require 'yaml'
require 'open-uri'
require 'digest/md5'
require 'cgi'
#require 'css_parser'
require '/home/ju1ius/code/ruby/css_parser/lib/css_parser.rb'
require File.expand_path(File.dirname(__FILE__) + '/premailer/adapter')
require File.expand_path(File.dirname(__FILE__) + '/premailer/adapter/hpricot')
require File.expand_path(File.dirname(__FILE__) + '/premailer/adapter/nokogiri')

require File.expand_path(File.dirname(__FILE__) + '/premailer/html_to_plain_text')
require File.expand_path(File.dirname(__FILE__) + '/premailer/premailer')
