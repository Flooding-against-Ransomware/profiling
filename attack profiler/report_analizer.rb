# The script takes as input the total list of files on the reference VM and the result of the FileChecker. 
# Analyze the results and create JSON whit a simple % ratio lost/save
# Ranflood - https://ranflood.netlify.app/
# https://notes.inria.fr/fEzRW8KJTM-Jr7vz2FHoiw?both#

require 'json'

# vecchia funzione
# def crea_struct(file_path)
#   risultato = {}

#   # Leggi il file linea per linea
#   File.foreach(file_path) do |linea|
#     # Divide la linea in percorso e hash
#     percorso, hash = linea.chomp.split(',')

#     # Aggiunge l'elemento alla struttura
#     risultato[hash] ||= []  # Inizializza l'array se non esiste già
#     risultato[hash] << percorso
#   end

#   return risultato
# end

def crea_struct(file_path)
  risultato = {}

  # Leggi il contenuto del file JSON
  json_content = File.read(file_path)
  data = JSON.parse(json_content)

  # Itera su ogni elemento nel formato JSON
  data.each do |elemento|
    # Estrai il percorso e l'hash dall'elemento
    percorso = elemento["path"]
    hash = elemento["checksum"]

    # Aggiungi l'elemento alla struttura
    risultato[hash] ||= []  # Inizializza l'array se non esiste già
    risultato[hash] << percorso
  end

  return risultato
end

def unisci_strutture(struttura1, struttura2)
  risultato = {}

  # Unisce i dati dalla struttura 1
  struttura1.each do |hash, path1|
    info = { "original" => path1.first, "status" => "", "replicas" => [] }
    
    # L'hash esiste anche nella struttura 2
    if struttura2.key?(hash)
      path2 = struttura2[hash]

      # Il percorso di path1 è presente anche in path2
      if path2.include?(path1.first)        
        info["status"] = "pristine"
        info["replicas"] = path2 - path1 # Aggiungo le repliche ma tolgo il percorso originale
      else
        info["status"] = "replica"
        info["replicas"] = path2
      end
    else
      # L'hash non esiste nella struttura 2
      info["status"] = "lost"
    end

    risultato[hash] = info
  end

  # Aggiungo le info dalla struttura 2
  struttura2.each do |hash, path2|
    unless risultato.key?(hash)
      # L'hash non esiste nella struttura 1
      risultato[hash] = {
        "original" => "",
        "status" => "replica",
        "replicas" => path2
      }
    end
  end

  return risultato
end


def crea_albero(input_hash)
  # output_hash = {  }
  output_hash = { "files" => {} , "folders"  =>  {} }

  input_hash.each do |hash, info|
    original_path = info["original"]
    status = info["status"]
    replicas = info["replicas"]

    # Estrai il nome del file dalla path
    file_name = File.basename(original_path)

    # Divide la path in cartelle
    path_parts = File.dirname(original_path).split("/")

    # Inizializza la struttura se non esiste
    current_folder = output_hash["folders"]
    
    # path_parts.each do |folder|
    #   current_folder[folder] ||= { "folders" => {}  }
    #   current_folder = current_folder[folder]["folders"]
    # end

    # Verifico se il percorso contiene il carattere "/", es non lo contiene è nella root
    if original_path.include?("/")
      # Inizializza la struttura se non esiste
      current_folder = output_hash["folders"]
      path_parts.each do |folder|
        current_folder[folder] ||= { "folders" => {}  }
        current_folder = current_folder[folder]["folders"]
      end


      # Inizializzo "files"
      current_folder["files"] ||= {}
      # Aggiungi il file corrente
      current_folder["files"][file_name] = {
        "name" => file_name,
        "checksum" => hash,
        "status" => status,
        "replicas" => replicas
      }
    else
      # Inizializza la struttura se non esiste
      current_folder = output_hash["files"]

      # Inizializzo "files"
      current_folder ||= {}
      # Aggiungi il file corrente
      current_folder[file_name] = {
        "name" => file_name,
        "checksum" => hash,
        "status" => status,
        "replicas" => replicas
      }
    end
  end

  return output_hash
end

# sposta di un livello in alto "files" nel JSON
def organizza_files(struct_albero)
  result = {}


  # alzo di un lvl tutti i "files"
  struct_albero.each do |key, value|
    if value.is_a?(Hash) && value.key?("folders") && value["folders"].key?("files")
      files = value["folders"].delete("files")
      value["files"] = files
    end
    
    result[key] = value.is_a?(Hash) ? organizza_files(value) : value
  end

  
  # chiavi_root = {  
  #   "folders"  =>  {}, 
  #   "files"  =>  {}
  # }

  # # aggiungo due livelli in root, files e folder
  # struct_albero =  chiavi_root.merge(struct_albero)

  # alzo di un lvl tutti i "." nel caso in cui ci siano file in root
  # struct_albero.each do |key, value|
  #   if value.is_a?(Hash) && value.key?(".") && value["."].key?("files")
  #     files = value["."].delete("files")
  #     value["files"] = files
  #   end
    
  #   result[key] = value.is_a?(Hash) ? organizza_files(value) : value
  # end

  result
end

def salva_json(albero, nome_file_output)
  albero = JSON.pretty_generate(albero)
  File.open(nome_file_output, 'w') do |file|
    file.puts(albero)
  end
end

if ARGV.length != 2
  puts "Usage: ruby report_analizer.rb <file_input1> <file_input2>"
  exit(1)
end

file_input_1 = ARGV[0]
file_input_2 = ARGV[1]
nome_file_output = 'tree_file_analysis.json'

struct_base = crea_struct(file_input_1)
# puts struct_base
# puts "-----------------------"
struct_contrasto = crea_struct(file_input_2)
# puts struct_contrasto

# puts "-----------------------"

struct_risultato = unisci_strutture(struct_base, struct_contrasto)
# puts struct_risultato

# elaborazione dell'hash in albero cartelle - file
struct_albero = crea_albero(struct_risultato)

nome_file_2_split = file_input_2.split('-')
parametri_test = {  
  "ransomware"  =>  nome_file_2_split[0], 
  "ranflood_delay"  =>  nome_file_2_split[1], 
  "strategy"  =>  nome_file_2_split[2],
  "root" => "C:/users/IEuser",
}


# trasformo in JSON
# struct_albero_JSON = JSON.pretty_generate(struct_albero)

# puts struct_albero_JSON

# sposto tutte le chiavi "files" di un livello in alto in modo da rispettare il formato desiderato
struct_albero_JSON = organizza_files(struct_albero)

# unisco i due hash info test  e albero cartelle
struct_albero_JSON =  parametri_test.merge(struct_albero_JSON)

salva_json(struct_albero_JSON, nome_file_output)

puts "Albero delle directory salvato in #{nome_file_output}"
