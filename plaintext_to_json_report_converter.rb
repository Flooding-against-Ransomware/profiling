require 'json'

Dir.glob("*.base") do | file |
  json = []
  File.open( file, 'r' ).each_line do | line |
    line = line.split(",")
    json.push( { path: line[0].strip() , checksum: line[1].strip() } )
  end
  filename = File.basename( file, ".base" )
  filename = "#{filename}.json"
  output = JSON.pretty_generate( json )
  File.open( "json/#{filename}", "w" ) do | f |
    f.write( output )
  end
end

