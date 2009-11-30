require 'rake'
require 'fileutils'
require 'lib/premailer'

desc 'Default: parse a URL.'
task :default => [:inline]

desc 'Parse a URL and write out the output.'
task :inline do
  url = ENV['url']
  output = ENV['output']
  
  if !url or url.empty? or !output or output.empty?
    puts 'Usage: rake inline url=http://example.com/ output=output.html'
    exit
  end

  premailer = Premailer.new(url, :warn_level => Premailer::Warnings::SAFE)
  fout = File.open(output, "w")
  fout.puts premailer.to_inline_css
  fout.close

  puts "Succesfully parsed '#{url}' into '#{output}'"
  puts premailer.warnings.length.to_s + ' CSS warnings were found'
end

task :text do
  url = ENV['url']
  output = ENV['output']
  
  if !url or url.empty? or !output or output.empty?
    puts 'Usage: rake text url=http://example.com/ output=output.txt'
    exit
  end

  premailer = Premailer.new(url, :warn_level => Premailer::Warnings::SAFE)
  fout = File.open(output, "w")
  fout.puts premailer.to_plain_text
  fout.close
  
  puts "Succesfully parsed '#{url}' into '#{output}'"
end
