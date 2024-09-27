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

  s.add_runtime_dependency 'addressable'
  s.add_runtime_dependency 'css_parser', '>= 1.19.0'
  s.add_runtime_dependency 'htmlentities', ['>= 4.0.0']
end
