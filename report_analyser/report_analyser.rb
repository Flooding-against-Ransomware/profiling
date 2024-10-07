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

def analizza_json(file_path, output_file)
  begin
    # Legge il contenuto del file JSON
    file_content = File.read( file_path )

    # Parsa il contenuto come JSON
    json_data = JSON.parse( file_content )

    # Analizza il JSON e conta gli status
    results = analizza_radice( json_data )

    # Salva i risultati in un file JSON
    salva_risultati( output_file, results )

  rescue StandardError => e
    puts "Errore durante l'analisi del file JSON: #{e.message}"
    puts e.backtrace
  end
end

# analizza radice per recuperare le cartelle dell'utente
def analizza_radice(data)
  # Inizializza l'hash dei risultati con le chiavi richieste
  results = {
    "ransomware" =>  data["ransomware"] ,
    "ranflood_delay" => data["ranflood_delay"] ,
    "strategy" => data["strategy"] ,
    "root" => data["root"] ,

    "total" => 0,
    "pristine" => 0,
    "replica" => 0,
    "replica_full" => 0,
    "lost" => 0,
    "folders" => {},
    "extensions" => Hash.new { |hash, key| hash[key] = Hash.new(0) }
  }

  conteggi_fold = {
    "pristine" => 0,
    "replica" => 0,
    "replica_full" => 0,
    "lost" => 0
  }
  conteggi_ext = {
    "pristine" => 0,
    "replica" => 0,
    "replica_full" => 0,
    "lost" => 0,
  }

  # Analizza i file nel livello corrente
  if data["files"].is_a?(Hash)
    data["files"].each do |k, v|
      ext = File.extname(v["name"]).downcase
      results["total"] += 1
      conteggi_fold[v["status"]] += 1
      results[v["status"]] += 1
      results["extensions"][ext]["total"] += 1
      results["extensions"][ext][v["status"]] += 1
      conteggi_ext[v["status"]] += 1
      if v["status"] == "replica"
        results["replica_full"] += v["replicas"].length
        results["extensions"][ext]["replica_full"] += v["replicas"].length
      end

      if conteggi_fold[v["status"]] != conteggi_ext[v["status"]]
        puts "Conteggio disallineato #{k}"
      end
    end
  end



  # Analizza le cartelle nel livello corrente
  if data["folders"].is_a?(Hash)
    data["folders"].each do |k, v|
      folder_results = analizza_cartella_ricorsivamente(v)
      results["total"] += folder_results["total"]
      results["pristine"] += folder_results["pristine"]
      results["replica"] += folder_results["replica"]
      results["replica_full"] += folder_results["replica_full"]
      results["lost"] += folder_results["lost"]
      results["folders"][k] = folder_results

      # Aggrega i risultati delle estensioni
      folder_results["extensions"].each do |ext, counts|
        results["extensions"][ext]["total"] += counts["total"]
        results["extensions"][ext]["pristine"] += counts["pristine"]
        results["extensions"][ext]["replica"] += counts["replica"]
        results["extensions"][ext]["replica_full"] += counts["replica_full"]
        results["extensions"][ext]["lost"] += counts["lost"]
      end
    end
  end

  results
end

# analizza cartella diversa dalla radice
def analizza_cartella_ricorsivamente(cartella)
  # Inizializza l'hash dei risultati della cartella
  folder_results = {
    "total" => 0,
    "pristine" => 0,
    "replica" => 0,
    "replica_full" => 0,
    "lost" => 0,
    "extensions" => Hash.new { |hash, key| hash[key] = Hash.new(0) }
  }

  # Analizza i file nella cartella corrente
  if cartella["files"].is_a?(Hash)
    cartella["files"].each do |k, v|
      ext = File.extname(v["name"]).downcase
      folder_results["total"] += 1
      folder_results[v["status"]] += 1
      folder_results["extensions"][ext]["total"] += 1
      folder_results["extensions"][ext][v["status"]] += 1
      if v["status"] == "replica"
        folder_results["replica_full"] += v["replicas"].length
        folder_results["extensions"][ext]["replica_full"] += v["replicas"].length
      end
    end
  end

  # Analizza le sottocartelle nella cartella corrente
  if cartella["folders"].is_a?(Hash)
    cartella["folders"].each do |k, v|
      subfolder_results = analizza_cartella_ricorsivamente(v)
      folder_results["total"] += subfolder_results["total"]
      folder_results["pristine"] += subfolder_results["pristine"]
      folder_results["replica"] += subfolder_results["replica"]
      folder_results["replica_full"] += subfolder_results["replica_full"]
      folder_results["lost"] += subfolder_results["lost"]

      # Aggrega i risultati delle estensioni delle sottocartelle
      subfolder_results["extensions"].each do |ext, counts|
        folder_results["extensions"][ext]["total"] += counts["total"]
        folder_results["extensions"][ext]["pristine"] += counts["pristine"]
        folder_results["extensions"][ext]["replica"] += counts["replica"]
        folder_results["extensions"][ext]["replica_full"] += counts["replica_full"]
        folder_results["extensions"][ext]["lost"] += counts["lost"]
      end
    end
  end

  folder_results
end



def salva_risultati( file_path, results )

  # Converte in JSON e salva nel file specificato
  File.open( file_path, 'w' ) { |file| 
   file.write( JSON.pretty_generate( results ) ) 
  }
  puts "Risultati salvati in #{file_path}"
end

if ARGV.length != 1
  puts "Usage: ruby report_analyser.rb <file_input1>"
  exit(1)
end

file_input = ARGV[0]

file_output = "#{file_input}_analysis.json"


directory = File.dirname(file_input)
nome_file_senza_estensione = File.basename(file_input, File.extname(file_input))
nome_file_nuovo = "#{nome_file_senza_estensione}-analysis.json"

file_output = File.join(directory, nome_file_nuovo);

analizza_json( file_input, file_output )