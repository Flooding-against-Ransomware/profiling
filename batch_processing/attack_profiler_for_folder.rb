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

# Verifica se sono stati forniti gli argomenti
if ARGV.length != 3
  puts "Uso: ruby profiling_folder.rb <path attack_profiler> <file_base> <directory>"
  exit
end

attack_profiler = File.expand_path(ARGV[0])
file_base = File.expand_path(ARGV[1])
directory = File.expand_path(ARGV[2])

puts file_base
puts directory

files = Dir.glob("#{directory}/*.json")
puts "File trovati: #{files.inspect}"  # Stampa i file trovati

# Scansiona la cartella e ottieni tutti i file
Dir.glob("#{directory}/*.json").each do |f|
  
  # Costruisci il comando per eseguire il primo script Ruby
  cmd = "ruby #{attack_profiler} #{file_base} #{f}"
  puts "Eseguo: #{cmd}"
  
  # Esegui il comando e stampa il risultato
  result = `#{cmd}`
  puts result
end