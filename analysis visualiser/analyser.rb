=begin

 * Copyright 2025 (C) by Saverio Giallorenzo <saverio.giallorenzo@gmail.com>  *
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

def _(_)
  _.nil? ? 0 : _
end

def analyse_file( path )
  data = JSON.parse( File.read( path ) )
  dir = File.dirname( path )
  path = File.basename( path, ".json" )
  result = {}
  result[ :total ] = data[ "pristine" ] + data[ "replica_full" ] + data[ "lost" ]
  result[ :pristine ] = data[ "pristine" ]
  result[ :replica ] = data[ "replica_full" ]
  result[ :lost ] = data[ "lost" ]
  result[ :pristine_perc ] = ( data[ "pristine" ].to_f / result[ :total ] ) * 100
  result[ :replica_perc ] = ( data[ "replica_full" ].to_f / result[ :total ] ) * 100
  result[ :lost_perc ] = ( data[ "lost" ].to_f / result[ :total ] ) * 100
  result[ :replica_distict ] = ( data[ "replica" ].to_f / data[ "replica_full" ] ) * 100

  puts "Analysing extensions of #{path}"
  # Ext analysis
  ext = result[ :extensions ] = {}
  keys = %i[ pristine replica lost ]
  keys.each{ |k| ext[k] = {} }
  data[ "extensions" ].each do | key |
    total = _(key[1][ "pristine" ]) + _(key[1][ "replica_full" ]) + _(key[1][ "lost" ])
    keys.each do | k |
      kk = k == :replica ? :replica_full : k
      ext[k][ key[0] ] = {
        percent: (_(key[1][ kk.to_s ]).to_f/result[k])*100,
        percent_dist: (_(key[1][ k.to_s ]).to_f / result[k])*100,
        internal_percent: ( _(key[1][ kk.to_s ]).to_f / total )*100
    }
    end
  end
  keys.each do | k |
    ext[ k ] = ext[ k ]
               .select{ |_,v| v[:percent] > 0 }
               .sort_by{ |_,v| -v[ :percent ] }
               .to_h
  end

  puts "Analysing folders of #{path}"
  # Folder analysis
  fold = result[ :folders ] = Hash.new
  keys.each{ |k| fold[k] = Hash.new }
  data[ "folders" ].each do | key |
    total = _(key[1][ "pristine" ]) + _(key[1][ "replica_full" ]) + _(key[1][ "lost" ])
    keys.each do | k |
      kk = k == :replica ? :replica_full : k
      fold[k][ key[0] ] = {
        percent: (_(key[1][ kk.to_s ]).to_f / result[k])*100,
        percent_dist: (_(key[1][ k.to_s ]).to_f / result[k])*100,
        internal_percent: ( _(key[1][ kk.to_s ]).to_f / total )*100
      }
    end
  end
  keys.each do |k|
    fold[ k ] = fold[ k ]
                .select{ |_,v| v[:percent] > 0 }
                .sort_by{ |_,v| -v[ :percent ] }
                .to_h
  end

  result = {
    path: dir + File::Separator + path,
    summary_total: {
      label: "",
      value: 100,
      subnodes: [ 
        { label: "pristine", value: result[ :pristine_perc ], subnodes:[] }, 
        { label: "replica", value: result[ :replica_perc ], subnodes:[] }, 
        { label: "lost", value: result[ :lost_perc ], subnodes:[] }
      ]
    },
    ext_pristine: {
      label: "folders",
      value: 100,
      subnodes: fold[ :pristine ].map{ |k, v| { label: k, value: v[ :percent ].round(2), subnodes: [] } } },
    ext_lost: {
      label: "folders",
      value: 100,
      subnodes: fold[ :lost ].map{ |k, v| { label: k, value: v[ :percent ].round(2), subnodes: [] } } },
    ext_replica: {
      label: "folders",
      value: 100,
      subnodes: fold[ :replica ].map{ |k, v| { 
        label: k, value: v[ :percent ].round(2), 
        subnodes: [ { label: "#{((v[ :percent_dist ] / v[ :percent ])*100).round(0)}\\%", value: v[ :percent_dist ], subnodes: [] } ] } } },
    fold_pristine: {
      label: "extensions",
      value: 100,
      subnodes: ext[ :pristine ].map{ |k, v| { label: k, value: v[ :percent ].round(2), subnodes: [] } } },
    fold_lost: {
      label: "extensions",
      value: 100,
      subnodes: ext[ :lost ].map{ |k, v| { label: k, value: v[ :percent ].round(2), subnodes: [] } } },
    fold_replica: {
      label: "extensions",
      value: 100,
      subnodes: ext[ :replica ].map{ |k, v| { 
        label: k, value: v[ :percent ].round(2), 
        subnodes: [ { label: "#{((v[ :percent_dist ] / v[ :percent ])*100).round(0)}\\%", value: v[ :percent_dist ].round(2), subnodes: [] } ] } } }
  }

  puts "Generating result file of #{path}"
  json_content = JSON.generate( result )
  File.write( "_result.json", json_content )
  puts "Plotting results of #{path}"
  `poetry run python visualiser.py`
  
  puts "Done"
end

file_path = ARGV[0]
if !file_path.nil? && File.exist?( file_path )
  analyse_file( file_path )
else
  puts "Error: provide a path to an existing .json report file"
end