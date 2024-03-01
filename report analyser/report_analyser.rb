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
    results = analizza_ricorsivamente( json_data )

    # Salva i risultati in un file JSON
    salva_risultati( output_file, results )

  rescue StandardError => e
    puts "Errore durante l'analisi del file JSON: #{e.message}"
    puts e.backtrace
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
  puts "Usage: ruby report_analyser.rb <file_input1>"
  exit(1)
end

file_input = ARGV[0]

file_output = "#{file_input}_analysis.json"

analizza_json( file_input, file_output )