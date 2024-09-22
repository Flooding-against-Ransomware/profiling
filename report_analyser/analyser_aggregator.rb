require 'json'
require 'pathname'

# Funzione per calcolare la deviazione standard
def standard_deviation(values,mean)
  return 0 if values.empty?
  
  # variance = values.map { |v| (v - mean)**2 }.sum / values.size.to_f

  sum_of_squares = values.map { |v| (v - mean)**2 }.sum # diff di ogni elemento rispetto alla media elevato al quadrato, poi somma totale
  variance = sum_of_squares / (values.size - 1).to_f  # Correzione di Bessel

  Math.sqrt(variance)
end

def aggregate_json(directory)
  files = Pathname.new(directory).children.select { |f| f.extname == '.json' }

  grouped_data = {}

  files.each do |file|
    data = JSON.parse(File.read(file))

    # Controlla se contiene le chiavi richieste
    if data.key?("ransomware") && data.key?("ranflood_delay") && data.key?("strategy") && data.key?("root")
      key = "#{data['ransomware']}-#{data['ranflood_delay']}-#{data['strategy']}-#{data['root']}"

      grouped_data[key] ||= {
        "ransomware" => data["ransomware"],
        "ranflood_delay" => data["ranflood_delay"],
        "strategy" => data["strategy"],
        "root" => data["root"],
        "total" => [],
        "pristine" => [],
        "replica" => [],
        "replica_full" => [],
        "lost" => []
      }

      grouped_data[key]["total"] << data["total"]
      grouped_data[key]["pristine"] << data["pristine"]
      grouped_data[key]["replica"] << data["replica"]
      grouped_data[key]["replica_full"] << data["replica_full"]
      grouped_data[key]["lost"] << data["lost"]
    end
  end

  # Calcola le somme, medie e le deviazioni standard per ogni gruppo
  grouped_data.each do |key, aggregated_data|
    output = {}
    output["count"] = aggregated_data["total"].size # n di elementi del gruppo
    output["ransomware"] = aggregated_data["ransomware"]
    output["ranflood_delay"] = aggregated_data["ranflood_delay"]
    output["strategy"] = aggregated_data["strategy"]
    output["root"] = aggregated_data["root"]

    ["total", "pristine", "replica", "replica_full", "lost"].each do |k|
      values = aggregated_data[k]
      next if values.empty?

      sum = values.sum
      mean = sum / values.size.to_f
      stddev = standard_deviation(values,mean)

      # Popolo l'hash con i dati calcolati e aggiungo le due nuove chiavi _avg e _stddev
      output[k] = sum
      output["#{k}_avg"] = mean
      output["#{k}_stddev"] = stddev
    end

    # Genera il nome del file nel formato richiesto
    sanitized_key = key.gsub(/[^\w\-]/, '_')  # Sostituisce caratteri non validi con _
    filename = "#{aggregated_data['ransomware']}-#{aggregated_data['ranflood_delay']}-#{aggregated_data['strategy']}-aggregatorOf-#{output['count']}.json"

    # Salva il risultato in un file JSON
    File.open(File.join(directory, filename), 'w') do |f|
      f.write(JSON.pretty_generate(output))
    end
  end
end

# Verifica se sono stati forniti gli argomenti
if ARGV.length != 1
  puts "Uso: ruby analyser_aggregator.rb <directory>"
  exit
end

directory = ARGV[0]  
aggregate_json(directory)
