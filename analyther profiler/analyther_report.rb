require 'json'

def analizza_json(file_path, output_file, key_analizzata)
  begin
    # Legge il contenuto del file JSON
    file_content = File.read(file_path)

    # Parsa il contenuto come JSON
    json_data = JSON.parse(file_content)

    # Inizializza una struttura per i conteggi
    conteggi = Hash.new(0)
    totale_status = [0]  

    # Analizza il JSON e conta gli status
    analizza_ricorsivamente(json_data, conteggi, totale_status, key_analizzata)

    # Stampa i risultati
    puts "Conteggi degli status:"
    conteggi.each { |status, conteggio| puts "#{status}: #{conteggio}" }
    puts "Totale status: #{totale_status[0]}"

    # Salva i risultati in un file JSON
    salva_risultati(output_file, conteggi, totale_status, key_analizzata)

  rescue StandardError => e
    puts "Errore durante l'analisi del file JSON: #{e.message}"
  end
end

def analizza_ricorsivamente(data, conteggi, totale_status, key_analizzata)
  # Controlla se l'oggetto corrente è un hash
  if data.is_a?(Hash)
    # Analizza ogni chiave-valore nell'hash
    data.each do |key, value|
      # Controlla se la chiave è 'status'
      if key == 'status'
        conteggi[value] += 1
        totale_status[0] += 1
      else
        # Se non è 'status', analizza ricorsivamente il valore
        analizza_ricorsivamente(value, conteggi, totale_status, key_analizzata)
      end
    end
  elsif data.is_a?(Array)
    # Se l'oggetto corrente è un array, analizza ogni elemento ricorsivamente
    data.each { |elemento| analizza_ricorsivamente(elemento, conteggi, totale_status, key_analizzata) }
  end
end

def salva_risultati(file_path, conteggi, totale_status, key_analizzata)
  risultati = { "chiave_cercata" => key_analizzata, "totale_chiavi" => totale_status[0], "valori_unici_chiave" => conteggi  }

  # Converte in JSON e salva nel file specificato
  File.open(file_path, 'w') { |file| file.write(JSON.pretty_generate(risultati)) }
  puts "Risultati salvati in #{file_path}"
end



if ARGV.length != 1
  puts "Usage: ruby analyther_report.rb <file_input1>"
  exit(1)
end

file_input = ARGV[0]

file_output = 'output_risultati.json' 
key_analizzata = 'status'

analizza_json(file_input, file_output, key_analizzata)