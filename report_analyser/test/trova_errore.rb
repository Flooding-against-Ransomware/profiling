require 'json'

def _(_)
  _.nil? ? 0 : _
end

def analyse_file( path )
  data = JSON.parse( File.read( path ) )
  values = [ "pristine", "lost", "replica_full" ]
  values.each do | v |
   ext = 0
   data[ "extensions" ].each do | k, j |
    ext += j[ v ]
   end
   fold = 0
   data[ "folders" ].each do | k, j |
    fold += j[ v ]
   end
   if( fold != ext )
    puts "#{v} - fold: #{fold}, ext: #{ext}, #{ext - fold}"
    puts 
   else
    puts "#{v} - fold: #{fold}, ext: #{ext}, #{ext - fold}"
   end
  end
end

analyse_file( "report_analyser\\test\\Phobos-30-NONE-4-report-analysis.json" )