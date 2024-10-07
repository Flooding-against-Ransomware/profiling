
# Verifica se sono stati forniti gli argomenti
if ARGV.length != 3
  puts "Uso: ruby profiling_folder.rb <path attack_profiler> <file_base> <directory>"
  exit
end

attack_profiler = File.expand_path(ARGV[0])
file_base = File.expand_path(ARGV[1])
directory = File.expand_path(ARGV[2])

puts file_base
puts directory

files = Dir.glob("#{directory}/*.json")
puts "File trovati: #{files.inspect}"  # Stampa i file trovati

# Scansiona la cartella e ottieni tutti i file
Dir.glob("#{directory}/*.json").each do |f|
  
  # Costruisci il comando per eseguire il primo script Ruby
  cmd = "ruby #{attack_profiler} #{file_base} #{f}"
  puts "Eseguo: #{cmd}"
  
  # Esegui il comando e stampa il risultato
  result = `#{cmd}`
  puts result
end