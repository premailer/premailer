source "https://rubygems.org"

gem 'css_parser', :git => 'git://github.com/premailer/css_parser.git'
gem 'webmock', :group => [:development, :test]

platforms :jruby do
  gem 'jruby-openssl'
end

gemspec

gem "ripper", :group => :development, :platforms => :mri_18

gem "coveralls", :require => false, :platforms => [:mri_19, :mri_20], :group => :development

gem 'test-unit', :group => [:development, :test], :platforms => [:mri_20, :mri_22]
