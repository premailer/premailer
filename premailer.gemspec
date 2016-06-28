require './lib/premailer/version'

Gem::Specification.new "premailer", Premailer::VERSION do |s|
  s.summary  = "Preflight for HTML e-mail."
  s.email    = "code@dunae.ca"
  s.homepage = "http://premailer.dialect.ca/"
  s.description = "Improve the rendering of HTML emails by making CSS inline, converting links and warning about unsupported code."
  s.has_rdoc = true
  s.author  = "Alex Dunae"
  s.files            = `git ls-files lib misc LICENSE.md README.md`.split("\n")
  s.executables      = ['premailer']
  s.required_ruby_version = '>= 2.0.0'

  s.add_dependency('css_parser', '>= 1.4.5')
  s.add_dependency('htmlentities', ['>= 4.0.0'])
  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency('rake', ['> 0.8',  '!= 0.9.0'])
  s.add_development_dependency('hpricot', '>= 0.8.3')
  s.add_development_dependency('nokogiri', '>= 1.4.4')
  s.add_development_dependency('yard', '~> 0.8.7.6')
  s.add_development_dependency('redcarpet', '~> 3.0')
  s.add_development_dependency('maxitest')
  s.add_development_dependency('coveralls')
  s.add_development_dependency('webmock')
  s.add_development_dependency('nokogumbo')
end

