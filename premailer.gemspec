GEM_ROOT = File.dirname(__FILE__).freeze  unless defined?(GEM_ROOT)

lib_path = File.expand_path('lib', GEM_ROOT)
$LOAD_PATH.unshift(lib_path)  unless $LOAD_PATH.include? lib_path

require 'premailer/version'

Gem::Specification.new do |s|
  s.name     = "premailer"
  s.version  = Premailer::VERSION.dup
  s.date = Time.now.strftime('%Y-%m-%d')
  s.summary  = "Preflight for HTML e-mail."
  s.email    = "code@dunae.ca"
  s.homepage = "http://premailer.dialect.ca/"
  s.description = "Improve the rendering of HTML emails by making CSS inline, converting links and warning about unsupported code."
  s.has_rdoc = true
  s.author  = "Alex Dunae"
  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables      = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.add_dependency('css_parser', '>= 1.3.6')
  s.add_dependency('htmlentities', ['>= 4.0.0'])
  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency('rake', ['~> 0.8',  '!= 0.9.0'])
  s.add_development_dependency('hpricot', '>= 0.8.3')
  s.add_development_dependency('nokogiri', '>= 1.4.4')
  s.add_development_dependency('yard', '~> 0.8.7.6')
  s.add_development_dependency('redcarpet', '~> 3.0')
end

