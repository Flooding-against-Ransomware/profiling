# The script takes as input the total list of files on the reference VM and the result of the FileChecker. 
# Analyze the results and create JSON whit a simple % ratio lost/save
# Ranflood - https://ranflood.netlify.app/

require 'json'

def crea_albero_directory(file_path)
  albero = {}

  File.foreach(file_path) do |riga|
    riga_split = riga.chomp.split(',')
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

def aggiorna_status(albero, nome, checksum)
  albero.each_value do |sottoalbero|
    risultato = trova_in_sottoalbero(sottoalbero, nome, checksum)
    return risultato if risultato
  end

  false
end

def trova_in_sottoalbero(sottoalbero, nome, checksum)
  sottoalbero.each do |file, dettagli|
    if dettagli.is_a?(Hash) && dettagli['name'] == nome && dettagli['checksum'] == checksum
      dettagli['status'] = 'original'
    elsif dettagli.is_a?(Hash) && dettagli.key?('name') && dettagli['checksum'] == checksum
      dettagli['status'] = 'replicated' 
      dettagli['replicated_name'] = nome 
    elsif dettagli.is_a?(Hash)
      risultato = trova_in_sottoalbero(dettagli, nome, checksum)
      return risultato if risultato
    end
  end

  false
end


def aggiorna_albero_directory(albero, file_path_2)
  File.foreach(file_path_2) do |riga|
    riga_split = riga.chomp.split(',')
    elementi_percorso = riga_split[0].split('/')

    nome_file = elementi_percorso.last.to_s 
    checksum = riga_split[1].to_s 

    aggiorna_status(albero, nome_file, checksum)

    
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
file_output = 'tree_file_analysis.json'

albero_directory = crea_albero_directory(file_input_1)
albero_directory = aggiorna_albero_directory(albero_directory, file_input_2)
salva_json(albero_directory, file_output)

puts "Albero delle directory salvato in #{file_output}"
