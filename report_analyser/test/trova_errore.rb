require 'json'

def _(_)
  _.nil? ? 0 : _
end

def analyse_file( path )
  data = JSON.parse( File.read( path ) )
  pristine_ext = 0
  pristine = 0
  data[ "extensions" ].each do | k, v |
   pristine_ext += v[ "pristine" ]
  end
  puts pristine_ext
  data[ "folders" ].each do | k, v |
   pristine += v[ "pristine" ]
  end
  puts pristine
end

analyse_file( "Phobos-30-NONE-4-report-analysis.json" )