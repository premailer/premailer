Gem::Specification.new do |s|
  s.name     = "premailer"
  s.version  = "1.5.5"
  s.date     = "2009-12-03"
  s.summary  = "Preflight for HTML e-mail."
  s.email    = "code@dunae.ca"
  s.homepage = "http://premailer.dialect.ca/"
  s.description = "Improve the rendering of HTML emails by making CSS inline, converting links and warning about unsupported code."
  s.has_rdoc = true
  s.author  = "Alex Dunae"
  s.rdoc_options << '--all' << '--inline-source' << '--line-numbers' << '--charset' << 'utf-8'
  s.files = FileList['*.rb', 'lib/premailer.rb', 'lib/**/*', '*.rdoc', 'misc/client_support.yaml', 'bin/*', 'test/*', 'test/**/*'].to_a
  s.executables = 'premailer'
  s.add_dependency('nokogiri', '>= 1.4.0')
  s.add_dependency('css_parser', '>= 0.9.1')
  #s.add_dependency('text-reform', '>= 0.2.0')
  s.add_dependency('htmlentities', '>= 4.0.0')
end
