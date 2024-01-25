# The script takes as input the total list of files on the reference VM and the result of the FileChecker. 
# Analyze the results and create JSON whit a simple % ratio lost/save
# Ranflood - https://ranflood.netlify.app/

require 'json'

def crea_albero_directory(file_path)
  albero = {}

  File.foreach(file_path) do |linea|
    parti = linea.chomp.split(',')
    elementi_percorso = parti[0].split('/')

    nodo_corrente = albero

    # scorro tutti gli elementi (cartelle) tranne l'ultimo che è il file
    # ||= assegna un valore solo se è "nil" o "false"
    elementi_percorso[0...-1].each do |elemento, indice|      
        nodo_corrente[elemento] ||= {}
        nodo_corrente = nodo_corrente[elemento] 
    end

    # aggiungo il file al ramo
    nodo_corrente[elementi_percorso.last] ||= []
    nodo_corrente[elementi_percorso.last] << { 'name' => elementi_percorso.last, 'checksum' => parti[1] }

    
    # nodo_corrente['_files'] ||= []
    # nodo_corrente['_files'] << { 'name' => elementi_percorso.last, 'checksum' => parti[1] }
  end

  albero
end

def salva_json(albero, file_output)
  json_data = JSON.pretty_generate(albero)

  File.open(file_output, 'w') do |file|
    file.puts(json_data)
  end
end

if ARGV.length != 1
  puts "Utilizzo: ruby script.rb <file_input>"
  exit(1)
end

file_input = ARGV[0]
file_output = 'directory_tree.json'

albero_directory = crea_albero_directory(file_input)
salva_json(albero_directory, file_output)

puts "Albero delle directory salvato in #{file_output}"
