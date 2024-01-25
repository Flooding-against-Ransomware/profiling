# The script takes as input the total list of files on the reference VM and the result of the FileChecker. 
# Analyze the results and create JSON whit a simple % ratio lost/save
# Ranflood - https://ranflood.netlify.app/

require 'json'

def crea_albero_directory(file_path)
  albero = {}

  File.foreach(file_path) do |linea|
    riga_split = linea.chomp.split(',')
    elementi_percorso = riga_split[0].split('/')

    nodo_corrente = albero

    # Scorri tutti gli elementi (cartelle) tranne l'ultimo che è il file
    # ||= assegna un valore solo se è "nil" o "false"
    elementi_percorso[0...-1].each do |elemento|
      nodo_corrente[elemento] ||= {}
      nodo_corrente = nodo_corrente[elemento]
    end

    # Aggiungi il file al ramo con status "lost" a tutti, lo modifico successivamente se lo trovo
    nodo_corrente[elementi_percorso.last] = { 'name' => elementi_percorso.last, 'checksum' => riga_split[1], 'status' => 'lost' }
  end

  albero
end

def aggiorna_albero_directory(albero, file_path_2)
  File.foreach(file_path_2) do |linea|
    riga_split = linea.chomp.split(',')
    elementi_percorso = riga_split[0].split('/')

    nodo_corrente = albero

    # Scorri tutti gli elementi (cartelle) tranne l'ultimo che è il file
    elementi_percorso[0...-1].each do |elemento|
      nodo_corrente = nodo_corrente[elemento]
      break if nodo_corrente.nil?  # Se il percorso non esiste, esci dal ciclo
    end

    # Se il file esiste, aggiorna lo status
    if nodo_corrente && nodo_corrente[elementi_percorso.last]
      if nodo_corrente[elementi_percorso.last]['checksum'] == riga_split[1]
        nodo_corrente[elementi_percorso.last]['status'] = 'original'
      else
        nodo_corrente[elementi_percorso.last]['status'] = 'replicated'
      end
    end
  end

  albero
end

def salva_json(albero, file_output)
  json_data = JSON.pretty_generate(albero)

  File.open(file_output, 'w') do |file|
    file.puts(json_data)
  end
end

if ARGV.length != 2
  puts "Usage: ruby reportAnalizer.rb <file_input1> <file_input2>"
  exit(1)
end

file_input_1 = ARGV[0]
file_input_2 = ARGV[1]
file_output = 'directory_tree.json'

albero_directory = crea_albero_directory(file_input_1)
albero_directory = aggiorna_albero_directory(albero_directory, file_input_2)
salva_json(albero_directory, file_output)

puts "Albero delle directory salvato in #{file_output}"
