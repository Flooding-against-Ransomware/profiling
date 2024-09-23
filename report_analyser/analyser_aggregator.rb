require 'json'
require 'pathname'

# Funzione per calcolare la deviazione standard
def standard_deviation(values,avg)
  return 0 if values.empty?
  
  # variance = values.map { |v| (v - avg)**2 }.sum / values.size.to_f

  sum_of_squares = values.map { |v| (v - avg)**2 }.sum # diff di ogni elemento rispetto alla media elevato al quadrato, poi somma totale
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
        "lost" => [],
        "extensions" => {},
        "folders" => {}
      }

      grouped_data[key]["total"] << data["total"]
      grouped_data[key]["pristine"] << data["pristine"]
      grouped_data[key]["replica"] << data["replica"]
      grouped_data[key]["replica_full"] << data["replica_full"]
      grouped_data[key]["lost"] << data["lost"]

      # aggrega estensioni in base al tipo
      if data.key?("extensions")
        data["extensions"].each do |ext, ext_data|
          grouped_data[key]["extensions"][ext] ||= {
            "total" => [],
            "pristine" => [],
            "replica" => [],
            "replica_full" => [],
            "lost" => []
          }

          grouped_data[key]["extensions"][ext]["total"] << ext_data["total"]
          grouped_data[key]["extensions"][ext]["pristine"] << ext_data["pristine"]
          grouped_data[key]["extensions"][ext]["replica"] << ext_data["replica"]
          grouped_data[key]["extensions"][ext]["replica_full"] << ext_data["replica_full"]
          grouped_data[key]["extensions"][ext]["lost"] << ext_data["lost"]
        end
      end # if per estensioni

      # Aggrega i dati delle cartelle
      if data.key?("folders") 
        data["folders"].each do |folder, folder_data|
          grouped_data[key]["folders"][folder] ||= {
            "total" => [],
            "pristine" => [],
            "replica" => [],
            "replica_full" => [],
            "lost" => [],
            "extensions" => {}
          }

          # Aggrega i dati principali della cartella
          grouped_data[key]["folders"][folder]["total"] << folder_data["total"]
          grouped_data[key]["folders"][folder]["pristine"] << folder_data["pristine"]
          grouped_data[key]["folders"][folder]["replica"] << folder_data["replica"]
          grouped_data[key]["folders"][folder]["replica_full"] << folder_data["replica_full"]
          grouped_data[key]["folders"][folder]["lost"] << folder_data["lost"]

          # Aggrega i dati delle estensioni nelle cartelle
          if folder_data.key?("extensions")
            folder_data["extensions"].each do |ext, ext_data|
              grouped_data[key]["folders"][folder]["extensions"][ext] ||= {
                "total" => [],
                "pristine" => [],
                "replica" => [],
                "replica_full" => [],
                "lost" => []
              }

              grouped_data[key]["folders"][folder]["extensions"][ext]["total"] << ext_data["total"]
              grouped_data[key]["folders"][folder]["extensions"][ext]["pristine"] << ext_data["pristine"]
              grouped_data[key]["folders"][folder]["extensions"][ext]["replica"] << ext_data["replica"]
              grouped_data[key]["folders"][folder]["extensions"][ext]["replica_full"] << ext_data["replica_full"]
              grouped_data[key]["folders"][folder]["extensions"][ext]["lost"] << ext_data["lost"]
            end
          end # if estensioni dentro cartelle

        end # ciclo ogni cartella
      end # if cartelle
    end # if controllo chiavi
  end # ciclo dei file

  #########

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
      avg = sum / values.size.to_f
      stddev = standard_deviation(values,avg)

      # Popolo l'hash con i dati calcolati e aggiungo le due nuove chiavi _avg e _stddev
      output[k] = sum
      output["#{k}_avg"] = avg
      output["#{k}_stddev"] = stddev
    end

    # Aggrega i dati delle estensioni
    output["extensions"] = {}
    aggregated_data["extensions"].each do |ext, ext_data|
      output["extensions"][ext] = {}

      ["total", "pristine", "replica", "replica_full", "lost"].each do |k|
        values = ext_data[k]
        next if values.empty?

        sum = values.sum
        avg = sum / values.size.to_f
        stddev = standard_deviation(values,avg)

        output["extensions"][ext][k] = sum
        output["extensions"][ext]["#{k}_avg"] = avg
        output["extensions"][ext]["#{k}_stddev"] = stddev
      end
    end

    # Aggrega cartelle e relative estensioni
    output["folders"] = {}
    aggregated_data["folders"].each do |folder, folder_data|
      output["folders"][folder] = {}

      # Calcolo di somme, medie e deviazioni standard per le cartelle
      ["total", "pristine", "replica", "replica_full", "lost"].each do |k|
        values = folder_data[k]
        next if values.empty?

        sum = values.sum
        avg = sum / values.size.to_f
        stddev = standard_deviation(values,avg)

        output["folders"][folder][k] = sum
        output["folders"][folder]["#{k}_avg"] = avg
        output["folders"][folder]["#{k}_stddev"] = stddev
      end

      # Aggrega i dati delle estensioni nelle cartelle
      # output["folders"][folder]["extensions"] = {}
      # folder_data["extensions"].each do |ext, ext_data|
      #   output["folders"][folder]["extensions"][ext] = {}

      #   ["total", "pristine", "replica", "replica_full", "lost"].each do |k|
      #     values = ext_data[k].compact  # Rimuovi eventuali valori nil
      #     next if values.empty?

      #     # valorizzare la chiave mancante con 0 in modo da non dare errori nei calcoli successivi
      #     ext_data[k] = [0] if values.empty?

      #     sum = values.sum 
      #     avg = sum / values.size.to_f
      #     stddev = standard_deviation(values,avg)

      #     output["folders"][folder]["extensions"][ext][k] = sum
      #     output["folders"][folder]["extensions"][ext]["#{k}_avg"] = avg
      #     output["folders"][folder]["extensions"][ext]["#{k}_stddev"] = stddev
      #   end
      # end # metriche estensioni della cartella

    end # metriche cartella



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
