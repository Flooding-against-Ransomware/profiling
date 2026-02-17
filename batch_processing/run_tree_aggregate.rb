#!/usr/bin/env ruby

require 'fileutils'

# Directory to process (current directory by default, or pass as argument)
target_dir = ARGV[0]
script_name = 'tree_aggreagate_report_analyser.rb'

# Get all subdirectories (excluding . and ..)
subdirs = Dir.entries(target_dir).select do |entry|
  path = File.join(target_dir, entry)
  File.directory?(path) && entry != '.' && entry != '..'
end

if subdirs.empty?
  puts "No subdirectories found in #{target_dir}"
  exit
end

puts "Found #{subdirs.length} subdirectory(ies)"
puts "=" * 50

subdirs.each do |subdir|
  subdir_path = File.join(target_dir, subdir)
  
  puts "\nProcessing: #{subdir}"
  puts "-" * 50
  
  if File.exist?(script_name)
    puts "Running #{script_name} in #{subdir}..."
    system("ruby #{script_name} #{subdir_path} #{target_dir}")
    
    if $?.success?
      puts "✓ Completed successfully"
    else
      puts "✗ Script failed with exit code: #{$?.exitstatus}"
    end
  else
    puts "⚠ Warning: #{script_name} not found in #{subdir}"
  end
end

puts "\n" + "=" * 50
puts "All subdirectories processed!"