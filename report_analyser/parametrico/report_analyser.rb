=begin

 * Copyright 2024 (C) by Saverio Giallorenzo <saverio.giallorenzo@gmail.com>  *
 * and Simone Melloni <melloni.simone@gmail.com>                              *
 *                                                                            *
 * This program is free software; you can redistribute it and/or modify       *
 * it under the terms of the GNU Library General Public License as            *
 * published by the Free Software Foundation; either version 2 of the         *
 * License, or (at your option) any later version.                            *
 *                                                                            *
 * This program is distributed in the hope that it will be useful,            *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of             *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *
 * GNU General Public License for more details.                               *
 *                                                                            *
 * You should have received a copy of the GNU Library General Public          *
 * License along with this program; if not, write to the                      *
 * Free Software Foundation, Inc.,                                            *
 * 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.                  *
 *                                                                            *
 * For details about the authors of this software, see the AUTHORS file.      *

 *  Ranflood - https://ranflood.netlify.app/                                  *

=end


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
  puts "Usage: ruby report_analyser.rb <file_input1>"
  exit(1)
end

file_input = ARGV[0]

file_output = 'output_risultati.json' 
key_analizzata = 'status'

analizza_json(file_input, file_output, key_analizzata)