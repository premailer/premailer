require 'rake'
require 'rake/testtask'
require "bundler/gem_tasks"
require 'yard'

GEM_ROOT = File.dirname(__FILE__).freeze  unless defined?(GEM_ROOT)

lib_path = File.expand_path('lib', GEM_ROOT)
$LOAD_PATH.unshift(lib_path)  unless $LOAD_PATH.include? lib_path

require 'premailer/version'

desc 'Parse a URL and write out the output.'
task :inline do
  require 'premailer'

  url = ENV['url']
  output = ENV['output']
  
  if !url or url.empty? or !output or output.empty?
    puts 'Usage: rake inline url=http://example.com/ output=output.html'
    exit
  end

  premailer = Premailer.new(url, :warn_level => Premailer::Warnings::SAFE, :verbose => true, :adapter => :nokogiri)
  File.open(output, "w") do |fout|
    fout.puts premailer.to_inline_css
  end

  puts "Succesfully parsed '#{url}' into '#{output}'"
  puts premailer.warnings.length.to_s + ' CSS warnings were found'
end

task :text do
  require 'premailer'

  url = ENV['url']
  output = ENV['output']
  
  if !url or url.empty? or !output or output.empty?
    puts 'Usage: rake text url=http://example.com/ output=output.txt'
    exit
  end

  premailer = Premailer.new(url, :warn_level => Premailer::Warnings::SAFE)
  File.open(output, "w") do |fout|
    fout.puts premailer.to_plain_text
  end
  
  puts "Succesfully parsed '#{url}' into '#{output}'"
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/test_*.rb']
  t.verbose = false
end

YARD::Rake::YardocTask.new do |yard|
  yard.options << "--title='Premailer #{Premailer::VERSION} Documentation'"
end

task :default => [:test]
