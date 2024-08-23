# frozen_string_literal: true
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
  s.required_ruby_version = '>= 3.0' # keep in sync with .github/workflows/actions.yml and .rubocop.yml
  s.metadata["yard.run"] = "yri" # use "yard" to build full HTML docs.
  s.metadata['rubygems_mfa_required'] = 'true'

  s.add_runtime_dependency 'css_parser', ['>= 1.12.0', '<= 1.17.1']
  s.add_runtime_dependency 'htmlentities', ['>= 4.0.0']
  s.add_runtime_dependency 'addressable'
  s.add_development_dependency "bundler", ">= 1.3"
  s.add_development_dependency 'rake', ['> 0.8',  '!= 0.9.0']
  s.add_development_dependency 'nokogiri', '~> 1.16'
  s.add_development_dependency 'redcarpet', '~> 3.0'
  s.add_development_dependency 'maxitest'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'bump'
  s.add_development_dependency 'rubocop', '~> 1.62.1' # locked to make bundle update not add new rules
  s.add_development_dependency 'rubocop-performance'
end
