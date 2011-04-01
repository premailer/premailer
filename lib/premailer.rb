require 'yaml'
require 'open-uri'
require 'digest/md5'
require 'cgi'
require 'css_parser'
require File.expand_path(File.dirname(__FILE__) + '/premailer/adapter')
require File.expand_path(File.dirname(__FILE__) + '/premailer/html_to_plain_text')
require File.expand_path(File.dirname(__FILE__) + '/premailer/premailer')
