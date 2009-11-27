Gem::Specification.new do |s|
  s.name     = "premailer"
  s.version  = "1.5.2"
  s.date     = "2009-11-27"
  s.summary  = "Preflight for HTML e-mail."
  s.email    = "code@dunae.ca"
  s.homepage = "http://premailer.dialect.ca/"
  s.description = "Improve the rendering of HTML emails by making CSS inline, converting links and warning about unsupported code."
  s.has_rdoc = true
  s.author  = "Alex Dunae"
  s.rdoc_options << '--all' << '--inline-source' << '--line-numbers' << '--charset' << 'utf-8'
  s.files = ['README.rdoc', 'CHANGELOG.rdoc', 'LICENSE.rdoc', 'lib/premailer.rb', 'lib/premailer/premailer.rb', 'lib/premailer/html_to_plain_text.rb', 'misc/client_support.yaml']
  s.add_dependency('hpricot', '>= 0.6')
  s.add_dependency('css_parser', '>= 0.9.0')
  s.add_dependency('text-reform', '>= 0.2.0')
end
