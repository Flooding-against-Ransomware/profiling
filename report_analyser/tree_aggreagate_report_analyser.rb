=begin

 * Copyright 2026 (C) by Saverio Giallorenzo <saverio.giallorenzo@gmail.com>  *
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
require 'pathname'

def aggregate_json( directory )
  files = Pathname.new( directory ).children.select { |f| f.extname == '.json' }

  grouped_data = {}
  first_file = true

  files.each do |file|
    data = JSON.parse(File.read(file))

    if data.key?( "report_type" ) && data[ "report_type" ] == "tree_aggregate"
      puts "Skipping #{file}"
      next
    end

    # Controlla se contiene le chiavi richieste
    if data.key?("ransomware") && 
       data.key?("ranflood_delay") && 
       data.key?("strategy") && 
       data.key?("root")

      if first_file
        grouped_data = grouped_data.merge({
          report_type: "tree_aggregate",
          ransomware: data["ransomware"],
          ranflood_delay: data["ranflood_delay"],
          strategy: data["strategy"],
          root: data["root"],
          files: {},
          folders: {}
        })
      else
        if grouped_data[ :ransomware ] != data["ransomware"] ||
           grouped_data[ :ranflood_delay ] != data["ranflood_delay"] ||
           grouped_data[ :strategy ] != data["strategy"] ||
           grouped_data[ :root ] != data["root"]
        raise "The report file #{file} has non-matching metadata: expected 
        ransomware = #{grouped_data[ :ransomware ]},  
        ranflood_delay = #{grouped_data[ :ranflood_delay ]},
        strategy = #{grouped_data[ :strategy ]},
        root = #{grouped_data[ :root ]}, found 
        ransomware = #{data["ransomware"]}
        ranflood_delay = #{data["ranflood_delay"]}
        strategy = #{data["strategy"]}
        root = #{data["root"]}"
        end
      end

      group_files( data[ "files" ], grouped_data[ :files ], first_file )
      group_folders( data[ "folders" ], grouped_data[ :folders ], first_file )
      
      first_file = false

    else
        raise "The report file #{file} has no metadata"
    end
  end

  save_results( directory, grouped_data )

end

def merge_status( status, agg )
  key = nil
  case status
    when "pristine"
      key = :pristine
    when "lost"
      key = :lost
    when "replica"
      key = :replica
    else
      puts "unrecognised status #{status}"
  end
  agg[ key ] += 1
  ## TODO: controllare che vengano fuori percentuali entro 1
  total = agg[ :lost ] + agg[ :pristine ] + agg[ :replica ]
  agg[ :lost_p ] = agg[ :lost ].to_f / total
  agg[ :pristine_p ] = agg[ :pristine ].to_f / total
  agg[ :replica_p ] = agg[ :replica ].to_f / total
end

def group_files( files, grouped_data, first_file )
  files.keys.each do | file |
    if first_file
         grouped_data[ file ] = {
          name: files[ file ][ "name" ],
          checksum: files[ file ][ "checksum" ],
          status: { lost: 0, pristine: 0, replica: 0 }
         }
    else
      if !grouped_data.key?( file )
        raise "Error, file found in a report not present in other report files"
      end
    end
    merge_status( files[ file ][ "status" ] , grouped_data[ file ][ :status ] )
  end
end

def group_folders( folders, grouped_data, first_file )
  folders.keys.each do | folder | 
      if first_file
        grouped_data[ folder ] = { files: {}, folders: {} }
      else
        if !grouped_data.key?( folder )
          raise "Error, folder found in a report not present in other report files"
        end
      end
      group_files( (-> ( f ){ f.nil? ? {} : f }).call(folders[ folder ][ "files" ]), grouped_data[ folder ][ :files ], first_file )
      group_folders( folders[ folder ][ "folders" ], grouped_data[ folder ][ :folders ], first_file )
  end
end

def save_results( dir, results )

  file_path = "#{results[ :ransomware ]}-#{results[ :ranflood_delay ]}-#{results[ :strategy ]}-tree_aggregate_report.json"
  file_path = File.join( dir, file_path )

  File.open( file_path, 'w' ) do |file| 
   file.write( JSON.pretty_generate( results ) )
  end
  puts "Results saved in #{file_path}"
end

if ARGV.length != 1
  puts "Usage: ruby tree_aggregate_report_analyser.rb <directory>"
  exit(1)
end

directory = ARGV[0]

aggregate_json( directory )