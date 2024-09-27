# frozen_string_literal: true
# keep Gemfile.lock checked in, because: https://grosser.it/2015/08/14/check-in-your-gemfile-lock/

source 'https://rubygems.org'

platforms :jruby do
  gem 'jruby-openssl'
end

group :development, :test do
  gem 'pry'
end

gemspec
gem 'bump', group: :development
gem 'webmock', group: :development
gem 'rubocop-performance', group: :development
gem 'rubocop', '~> 1.62.1', group: :development # locked to make bundle update not add new rules
gem 'redcarpet', '~> 3.0', group: :development
gem 'rake', ['> 0.8', '!= 0.9.0'], group: :development
gem 'nokogiri', '~> 1.16', group: :development
gem 'maxitest', group: :development # add_development_dependency
gem "bundler", ">= 1.3", group: :development
