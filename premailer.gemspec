Gem::Specification.new do |s|
  s.name     = "premailer"
  s.version  = "1.7.3"
  s.date = Time.now.strftime('%Y-%m-%d')
  s.summary  = "Preflight for HTML e-mail."
  s.email    = "code@dunae.ca"
  s.homepage = "http://premailer.dialect.ca/"
  s.description = "Improve the rendering of HTML emails by making CSS inline, converting links and warning about unsupported code."
  s.has_rdoc = true
  s.author   = "Alex Dunae"
  s.files    = %w[
    Gemfile
    LICENSE.md
    README.md
    bin/premailer
    init.rb
    lib/premailer.rb
    lib/premailer/adapter.rb
    lib/premailer/adapter/hpricot.rb
    lib/premailer/adapter/nokogiri.rb
    lib/premailer/executor.rb
    lib/premailer/html_to_plain_text.rb
    lib/premailer/premailer.rb
    local-premailer
    misc/client_support.yaml
    premailer.gemspec
    rakefile.rb
    test/files/base.html
    test/files/chars.html
    test/files/contact_bg.png
    test/files/dialect.png
    test/files/dots_end.png
    test/files/dots_h.gif
    test/files/html4.html
    test/files/import.css
    test/files/inc/2009-placeholder.png
    test/files/iso-8859-2.html
    test/files/iso-8859-5.html
    test/files/no_css.html
    test/files/noimport.css
    test/files/styles.css
    test/files/xhtml.html
    test/future_tests.rb
    test/helper.rb
    test/test_adapter.rb
    test/test_html_to_plain_text.rb
    test/test_links.rb
    test/test_misc.rb
    test/test_premailer.rb
    test/test_warnings.rb
  ]
  s.test_files = %w[
    test/files/base.html
    test/files/chars.html
    test/files/contact_bg.png
    test/files/dialect.png
    test/files/dots_end.png
    test/files/dots_h.gif
    test/files/html4.html
    test/files/import.css
    test/files/inc/2009-placeholder.png
    test/files/iso-8859-2.html
    test/files/iso-8859-5.html
    test/files/no_css.html
    test/files/noimport.css
    test/files/styles.css
    test/files/xhtml.html
    test/future_tests.rb
    test/helper.rb
    test/test_adapter.rb
    test/test_html_to_plain_text.rb
    test/test_links.rb
    test/test_misc.rb
    test/test_premailer.rb
    test/test_warnings.rb
  ]
  s.executables = %w[premailer]
  s.add_dependency('css_parser', '>= 1.1.9')
  s.add_dependency('htmlentities', '>= 4.0.0')
  s.add_development_dependency('hpricot', '>= 0.8.3')
  s.add_development_dependency('nokogiri', '>= 1.4.4')
  s.add_development_dependency('rake', ['~> 0.8',  '!= 0.9.0'])
  s.add_development_dependency('yard', '~> 0.7.3')
  s.add_development_dependency('redcarpet', '~> 1.17.2')
end

