require 'json'

def analizza_json(file_path, output_file)
  begin
    # Legge il contenuto del file JSON
    file_content = File.read( file_path )

    # Parsa il contenuto come JSON
    json_data = JSON.parse( file_content )

    # Analizza il JSON e conta gli status
    results = analizza_ricorsivamente( json_data )

    # Salva i risultati in un file JSON
    salva_risultati( output_file, results )

  rescue StandardError => e
    puts "Errore durante l'analisi del file JSON: #{e.message}"
  end
end

def analizza_ricorsivamente( data )
  results = Hash.new
  results[ "total" ] = 0
  results[ "pristine" ] = 0
  results[ "replica" ] = 0
  results[ "replica_full" ] = 0
  results[ "lost" ] = 0
  if ( data[ "files" ].is_a?( Hash ) )
    data[ "files" ].each do | k, v |
      results[ "total" ] += 1
      results[ v[ "status" ] ] += 1
      if( v[ "status" ] == "replica" )
        results[ "replica_full" ] += v[ "replicas" ].length
      end
    end
  end
  if ( data[ "folders" ].is_a?( Hash ) )
    data[ "folders" ].each do | k, v |
      results = results.merge( analizza_ricorsivamente( v ) ){ |k,vl,vr| vl + vr }
    end
  end
  return results
end

def salva_risultati( file_path, results )

  # Converte in JSON e salva nel file specificato
  File.open( file_path, 'w' ) { |file| 
   file.write( JSON.pretty_generate( results ) ) 
  }
  puts "Risultati salvati in #{file_path}"
end

if ARGV.length != 1
  puts "Usage: ruby analyther_report.rb <file_input1>"
  exit(1)
end

file_input = ARGV[0]

file_output = 'output_risultati.json' 

analizza_json( file_input, file_output )