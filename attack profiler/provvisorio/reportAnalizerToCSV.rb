# The script takes as input the total list of files on the reference VM and the result of the FileChecker. 
# Analyze the results and create a simple statistic
# Ranflood - https://ranflood.netlify.app/

require 'csv'

# Estrai estensione dal percorso file
def estrai_estensione(file_path)
  # Estrae la parte prima della virgola
  parte_prima_virgola = file_path.split(',').first

  # Estrae l'estensione dal nome del file
  estensione = File.extname(parte_prima_virgola)

  return estensione
end

# Verifica se l'utente ha fornito i percorsi dei file come argomenti
if ARGV.length != 2
  puts "Usage: ruby reportAnalizer.rb <percorso_file_1> <percorso_file_2>"
  exit
end

# Prende i percorsi dei file dagli argomenti della linea di comando
file_path_1, file_path_2 = ARGV

# Verifica se i file esistono
unless File.exist?(file_path_1) && File.exist?(file_path_2)
  puts "Almeno uno dei file non esiste. Verifica i percorsi e riprova."
  exit
end

# Conta il numero di righe nel file
numero_righe_1 = File.readlines(file_path_1).size
numero_righe_2 = File.readlines(file_path_2).size

# Inizializza un hash per tenere traccia delle cartelle e delle righe per ciascun file
cartelle_righe_file_1 = Hash.new(0)
cartelle_righe_file_2 = Hash.new(0)
estensioni_file_1 = Hash.new(0)
estensioni_file_2 = Hash.new(0)

# Legge il primo file e conta le righe per ciascuna cartella
File.foreach(file_path_1) do |riga|
  # Estrae la cartella dal percorso del file
  percorsi = riga.split(',')[0].split('/')
  
  # Se ci sono almeno due cartelle, incrementa il conteggio per la prima cartella
  if percorsi.length >= 1
    cartelle_righe_file_1[percorsi[0]] += 1
  end

  estensioni_file_1[estrai_estensione(riga)] += 1
end

# Legge il secondo file e conta le righe per ciascuna cartella
File.foreach(file_path_2) do |riga|
  # Estrae la cartella dal percorso del file
  percorsi = riga.split(',')[0].split('/')
  
  # Se ci sono almeno due cartelle, incrementa il conteggio per la prima cartella
  if percorsi.length >= 1
    cartelle_righe_file_2[percorsi[0]] += 1
  end

  estensioni_file_2[estrai_estensione(riga)] += 1
end

puts "Folder;WM baseline;WM tested;% saved"
puts  "Total;#{numero_righe_1};#{numero_righe_2};#{((numero_righe_2.to_f / numero_righe_1) * 100).round(2)}"

risultati = []
risultati << {
  'Folder' => 'Total',
  'WM baseline' => numero_righe_1,
  'WM tested' => numero_righe_2,
  'R% saved' => ((numero_righe_2.to_f / numero_righe_1) * 100).round(2),
}

cartelle_righe_file_1.keys.each do |cartella|  
  righe_file_1 = cartelle_righe_file_1[cartella]
  righe_file_2 = cartelle_righe_file_2[cartella]
  percentuale = (righe_file_2.to_f / righe_file_1) * 100

  puts "#{cartella};#{righe_file_1};#{righe_file_2};#{percentuale.round(2)}"

  risultati << {
    'Folder' => cartella,
    'WM baseline' => righe_file_1,
    'WM tested' => righe_file_2,
    'R% saved' => ((righe_file_2.to_f / righe_file_1) * 100).round(2),
  }

end

estensioni_file_1.keys.each do |estensione|  
  estensione_file_1 = estensioni_file_1[estensione]
  estensione_file_2 = estensioni_file_2[estensione]
  percentuale = (estensione_file_2.to_f / estensione_file_1) * 100

  puts "#{estensione};#{estensione_file_1};#{estensione_file_2};#{percentuale.round(2)}"

  risultati << {
    'Folder' => estensione,
    'WM baseline' => estensione_file_1,
    'WM tested' => estensione_file_2,
    'R% saved' => ((estensione_file_2.to_f / estensione_file_1) * 100).round(2),
  }

end

output_csv = 'Analyses-' + file_path_2 + '.csv'

CSV.open(output_csv, 'w', write_headers: true, headers: risultati.first.keys) do |csv|
  risultati.each { |risultato| csv << risultato.values }
end



