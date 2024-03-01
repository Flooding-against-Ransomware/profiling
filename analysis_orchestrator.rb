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
