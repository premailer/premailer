require './lib/premailer/version'

Gem::Specification.new "premailer", Premailer::VERSION do |s|
  s.summary  = "Preflight for HTML e-mail."
  s.email    = "akzhan.abdulin@gmail.com"
  s.homepage = "https://github.com/premailer/premailer"
  s.description = "Improve the rendering of HTML emails by making CSS inline, converting links and warning about unsupported code."
  s.license = "BSD-3-Clause"
  s.author  = "Alex Dunae"
  s.files            = `git ls-files lib misc LICENSE.md README.md`.split("\n")
  s.executables      = ['premailer']
  s.required_ruby_version = '>= 2.5.0'
  s.metadata["yard.run"] = "yri" # use "yard" to build full HTML docs.

  s.add_runtime_dependency('css_parser', '>= 1.6.0')
  s.add_runtime_dependency('htmlentities', ['>= 4.0.0'])
  s.add_runtime_dependency 'addressable'
  s.add_development_dependency "bundler", ">= 1.3"
  s.add_development_dependency('rake', ['> 0.8',  '!= 0.9.0'])
  s.add_development_dependency('nokogiri', '~> 1.8.2')
  s.add_development_dependency('redcarpet', '~> 3.0')
  s.add_development_dependency('maxitest')
  s.add_development_dependency('coveralls')
  s.add_development_dependency('webmock')
  s.add_development_dependency('nokogumbo')
  s.add_development_dependency('bump')
end

