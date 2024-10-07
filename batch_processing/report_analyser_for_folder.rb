# Verifica se sono stati forniti gli argomenti
if ARGV.length != 2
  puts "Uso: ruby report_analyser.rb <path attack_profiler> <directory>"
  exit
end

report_analyser = File.expand_path(ARGV[0])
directory = File.expand_path(ARGV[1])

puts directory

files = Dir.glob("#{directory}/*.json")
puts "File trovati: #{files.inspect}"  # Stampa i file trovati

# Scansiona la cartella e ottieni tutti i file
Dir.glob("#{directory}/*.json").each do |f|
  
  # Costruisci il comando per eseguire il primo script Ruby
  cmd = "ruby #{report_analyser} #{f}"
  puts "Eseguo: #{cmd}"
  
  # Esegui il comando e stampa il risultato
  result = `#{cmd}`
  puts result
end