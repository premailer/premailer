Gem::Specification.new do |s|
  s.name     = "premailer"
  s.version  = "1.6.2"
  s.date     = "2010-11-22"
  s.summary  = "Preflight for HTML e-mail."
  s.email    = "code@dunae.ca"
  s.homepage = "http://premailer.dialect.ca/"
  s.description = "Improve the rendering of HTML emails by making CSS inline, converting links and warning about unsupported code."
  s.has_rdoc = true
  s.author  = "Alex Dunae"
  s.rdoc_options << '--all' << '--inline-source' << '--line-numbers' << '--charset' << 'utf-8'
  s.extra_rdoc_files = ["README.rdoc"]  
  s.files = [
    "init.rb",
    "bin/premailer",
    "lib/ts_premailer.rb",
    "lib/ts_premailer/html_to_plain_text.rb",
    "lib/ts_premailer/premailer.rb",
    "lib/ts_premailer/adapter.rb",
    "lib/ts_premailer/adapter/hpricot.rb",
    "lib/ts_premailer/adapter/nokogiri.rb",
    "misc/client_support.yaml"
  ]
  s.executables = 'premailer'
  s.add_dependency('hpricot', '>= 0.8.3')
  s.add_dependency('css_parser', '>= 1.1.6')
  s.add_dependency('htmlentities', '>= 4.0.0')
end
