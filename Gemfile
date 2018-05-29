# Keep Gemfile.lock from repo. Reason: https://grosser.it/2015/08/14/check-in-your-gemfile-lock/

source "https://rubygems.org"

gem 'css_parser', :git => 'https://github.com/premailer/css_parser.git'

group :development, :test do
  gem 'rspec-core'
end

platforms :jruby do
  gem 'jruby-openssl'
end

gemspec
