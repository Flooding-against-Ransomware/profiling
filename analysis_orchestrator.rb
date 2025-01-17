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
require 'set'

folders=["onlyWanna", "WannaRandom15", "WannaRandom30", "WannaRandom60"]
folders.each do | folder |
  Dir.glob( "#{folder}/*.log" ).each do | f | 
   cmd = "ruby attack_profiler.rb profile.json #{f}"
   puts cmd
   result = `#{cmd}`
   puts result
   cmd = "ruby report_analyser.rb #{f}_report.json"
   result = `#{cmd}`
   puts result
  end
end

result = {}
folders.each do | folder |
  _result = {}
  Dir.glob( "#{folder}/*_analysis.json" ).each do | f |
   d = JSON.parse( File.read( f ) )
   d.keys().each do | k |
    _result[ k ] ||= []
    _result[ k ].push( d[ k ] )
   end
   result[ f.split( "/" )[0] ] = _result
  end
end
result.keys().each do | k |
 _r = result[ k ]
 if _r[ "total" ].to_set.size() != 1
  raise Excepiton.new( "The total number of files is different among the logs, check. The totale number of files should always be the same among the tests" )
 else
  _r[ "total" ] = _r[ "total" ][0]
 end
 [ "pristine", "replica", "replica_full", "lost" ].each do | j |
  _r[ j ] = _r[ j ].sum( 0.0 ) / _r[ j ].size()
 end
end
total = {}
result.keys().each do | k |
 total[ k ] = {}
 total[ k ][ "pristine" ] ||= []
 total[ k ][ "replica" ] ||= []
 total[ k ][ "pristine" ].push( 
  (100*(result[ k ][ "pristine" ]/result[ k ][ "total" ])).round(2) )
 total[ k ][ "replica" ].push( 
  ((100*result[ k ][ "replica" ]/result[ k ][ "total" ])).round(2) )
end
puts total
