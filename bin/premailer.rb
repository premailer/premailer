#!/usr/bin/env ruby
#
# = Premailer
#
# TODO: handle plain text with no outputfile
require 'trollop'
require File.join(File.dirname(__FILE__), '../lib/premailer')

opts = Trollop::options do
  version "Premailer #{Premailer::VERSION} (c) 2008-2009 Alex Dunae"
  banner <<-EOS
Improve the rendering of HTML emails by making CSS inline, converting links and warning about unsupported code.

Usage:
       premailer [options] inputfile [outputfile]
where [options] are:
EOS
  opt :base_url, "Manually set the base URL, useful for local files", :type => String
  opt :plain_text, "Create a plain text version?  Appends .txt to the output file name.", :default => false, :short => 't'
  opt :query_string, "Query string to append to links", :type => String, :short => 'q'
  opt :show_warnings, "Show warnings", :default => false, :short => 'w'
  opt :line_length, "Length of lines when creating plaintext version", :type => :int, :default => 65
  opt :remove_classes, "Remove classes from the HTML document?", :default => false
end

infile = ARGV.shift
outfile = ARGV.shift

if infile.nil?
  Trollop::die "inputfile is missing"
end

premailer_opts = {
  :base_url => opts[:base_url],
  :query_string => opts[:query_string],
  :show_warnings => opts[:show_warnings] ? Premailer::Warnings::SAFE : Premailer::Warnings::NONE,
  :line_length => opts[:line_length],
  :remove_classes => opts[:remove_classes]
}

premailer = Premailer.new(infile, premailer_opts)
if outfile
  fout = File.open(outfile, 'w')
  fout.puts premailer.to_inline_css
  fout.close
else
  p premailer.to_inline_css
  exit
end

if opts[:plain_text]
  fout = File.open(outfile + '.txt', 'w')
  fout.puts premailer.to_plain_text
  fout.close
end

if opts[:show_warnings]
  premailer.warnings.each do |w|
    puts "- #{w[:message]} (#{w[:level]}) may not render properly in #{w[:clients]}"
  end
end
