# -*- encoding: UTF-8 -*-

require File.expand_path(File.dirname(__FILE__)) + '/helper'

class TestPremailer < Premailer::TestCase
  def test_special_characters_nokogiri
    html = 	'<p>cédille c&eacute; & garçon gar&#231;on à &agrave; &nbsp; &amp; &copy;</p>'
    premailer = Premailer.new(html, :with_html_string => true, :adapter => :nokogiri)
    premailer.to_inline_css
    assert_equal 'c&eacute;dille c&eacute; &amp; gar&ccedil;on gar&ccedil;on &agrave; &agrave; &nbsp; &amp; &copy;', premailer.processed_doc.at('p').inner_html
  end

  def test_special_characters_nokogiri_remote
    remote_setup('chars.html', :adapter => :nokogiri)
    @premailer.to_inline_css
    assert_equal 'c&eacute;dille c&eacute; &amp; gar&ccedil;on gar&ccedil;on &agrave; &agrave; &nbsp; &amp; &copy;', @premailer.processed_doc.at('p').inner_html
  end

  #def test_cyrillic_nokogiri_remote
  #  if RUBY_VERSION =~ /1.9/
  #    remote_setup('iso-8859-5.html', :adapter => :nokogiri) #, :encoding => 'iso-8859-5')
  #  	@premailer.to_inline_css
  #    assert_equal Encoding.find('ISO-8859-5'), @premailer.processed_doc.at('p').inner_html.encoding
  #  end
  #end

  def test_detecting_html
    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      remote_setup('base.html', :adapter => adapter)
      assert !@premailer.is_xhtml?
    end
  end

  def test_detecting_xhtml
    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      remote_setup('xhtml.html', :adapter => adapter)
      assert @premailer.is_xhtml?
    end
  end

  def test_self_closing_xhtml_tags
    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      remote_setup('xhtml.html', :adapter => adapter)
      assert_match /<br[\s]*\/>/, @premailer.to_s
      assert_match /<br[\s]*\/>/, @premailer.to_inline_css
    end
  end

  def test_non_self_closing_html_tags
    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      remote_setup('html4.html', :adapter => adapter)
      assert_match /<br>/, @premailer.to_s
      assert_match /<br>/, @premailer.to_inline_css
    end
  end

  def test_mailtos_with_query_strings
    html = <<END_HTML
    <html>
		<a href="mailto:info@example.com?subject=Programmübersicht&amp;body=Lorem ipsum dolor sit amet.">Test</a>
		</html>
END_HTML

    qs = 'testing=123'

    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      premailer = Premailer.new(html, :with_html_string => true, :link_query_string => qs, :adapter => adapter)
      premailer.to_inline_css
      refute_match /testing=123/, premailer.processed_doc.search('a').first.attributes['href'].to_s
    end
  end

  def test_preserving_ignored_style_elements
    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      local_setup('ignore.html', :adapter => adapter)

      assert_nil @doc.at('h1')['style']
    end
  end

  def test_preserving_ignored_link_elements
    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      local_setup('ignore.html', :adapter => adapter)

      assert_nil @doc.at('body')['style']
    end
  end

  def test_importing_local_css
    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      local_setup('base.html', :adapter => adapter)

      # noimport.css (print stylesheet) sets body { background } to red
      refute_match /red/, @doc.at('body').attributes['style'].to_s

      # import.css sets .hide to { display: none }
      assert_match /display: none/, @doc.at('#hide01').attributes['style'].to_s
    end
  end

  def test_css_to_attributes
    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      html = '<td style="background-color: #FFF;"></td>'
      premailer = Premailer.new(html, {:with_html_string => true, :adapter => adapter, :css_to_attributes => true})
      premailer.to_inline_css
      assert_equal '', premailer.processed_doc.search('td').first.attributes['style'].to_s
      assert_equal '#FFFFFF', premailer.processed_doc.search('td').first.attributes['bgcolor'].to_s
    end
  end

  def test_avoid_changing_css_to_attributes
    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      html = '<td style="background-color: #FFF;"></td>'
      premailer = Premailer.new(html, {:with_html_string => true, :adapter => adapter, :css_to_attributes => false})
      premailer.to_inline_css
      assert_match /background-color: #FFF/, premailer.processed_doc.at_css('td').attributes['style'].to_s
    end
  end

  def test_importing_remote_css
    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      remote_setup('base.html', :adapter => adapter)

      # noimport.css (print stylesheet) sets body { background } to red
      refute_match /red/, @doc.at('body')['style']

      # import.css sets .hide to { display: none }
      assert_match /display: none/, @doc.at('#hide01')['style']
    end
  end

  def test_importing_css_as_string
    files_base = File.expand_path(File.dirname(__FILE__)) + '/files/'

    css_string = IO.read(File.join(files_base, 'import.css'))

    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      premailer = Premailer.new(File.join(files_base, 'no_css.html'), {:css_string => css_string, :adapter => adapter})
      premailer.to_inline_css
      @doc = premailer.processed_doc

      # import.css sets .hide to { display: none }
      assert_match /display: none/, @doc.at('#hide01')['style']
    end
  end

  def test_local_remote_check
    assert Premailer.local_data?( StringIO.new('a') )
    assert Premailer.local_data?( '/path/' )
    assert !Premailer.local_data?( 'http://example.com/path/' )

    # the old way is deprecated but should still work
    premailer = Premailer.new( StringIO.new('a') )
    silence_stderr do
      assert premailer.local_uri?( '/path/' )
    end
  end

  def test_initialize_can_accept_io_object
    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      io = StringIO.new('hi mom')
      premailer = Premailer.new(io, :adapter => adapter)
      assert_match /hi mom/, premailer.to_inline_css
    end
  end

  def test_initialize_can_accept_html_string
    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      premailer = Premailer.new('<p>test</p>', :with_html_string => true, :adapter => adapter)
      assert_match /test/, premailer.to_inline_css
    end
  end

  def test_initialize_no_escape_attributes_option
    html = <<END_HTML
    <html> <body>
    <a id="google" href="http://google.com">Google</a>
    <a id="noescape" href="{{link_url}}">Link</a>
		</body> </html>
END_HTML

    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      pm = Premailer.new(html, :with_html_string => true, :adapter => adapter, :escape_url_attributes => false)
      pm.to_inline_css
      doc = pm.processed_doc
      assert_equal doc.at('#google')['href'], 'http://google.com'
      assert_equal doc.at('#noescape')['href'], '{{link_url}}'
    end
  end

  def test_remove_ids
    html = <<END_HTML
    <html> <head> <style type="text/css"> #remove { color:blue; } </style> </head>
    <body>
		<p id="remove"><a href="#keep">Test</a></p>
		<p id="keep">Test</p>
		</body> </html>
END_HTML

    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      pm = Premailer.new(html, :with_html_string => true, :remove_ids => true, :adapter => adapter)
      pm.to_inline_css
      doc = pm.processed_doc
      assert_nil doc.at('#remove')
      assert_nil doc.at('#keep')
      hashed_id = doc.at('a')['href'][1..-1]
      refute_nil doc.at("\##{hashed_id}")
    end
  end

  def test_reset_contenteditable
    html = <<-___
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html> <head> <style type="text/css"> #remove { color:blue; } </style> </head>
    <body>
    <div contenteditable="true" id="editable"> Test </div>
    </body> </html>
    ___
    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      pm = Premailer.new(html, :with_html_string => true, :reset_contenteditable => true, :adapter => adapter)
      pm.to_inline_css
      doc = pm.processed_doc
      assert_nil doc.at_css('#editable')['contenteditable'],
                 "#{adapter}: contenteditable attribute not removed"
    end
  end

  def test_carriage_returns_as_entities
    html = <<-html
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html>
    <body>\n\r<p>test</p>\n\r<p>test</p>
    </body></html>
    html

    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      pm = Premailer.new(html, :with_html_string => true, :adapter => adapter)
      assert_match /\n/, pm.to_inline_css
    end
  end


  def test_advanced_selectors
    remote_setup('base.html', :adapter => :nokogiri)
    assert_match /italic/, @doc.at('h2 + h3')['style']
    assert_match /italic/, @doc.at('p[attr~=quote]')['style']
    assert_match /italic/, @doc.at('ul li:first-of-type')['style']
  end

  def test_premailer_related_attributes
    html = <<END_HTML
    <html> <head> <style>table { -premailer-width: 500; } td { -premailer-height: 20}; </style>
    <body>
		<table> <tr> <td> Test </td> </tr> </table>
		</body> </html>
END_HTML

    [:nokogiri, :nokogiri_fast, :nokogumbo].each do |adapter|
      pm = Premailer.new(html, :with_html_string => true, :adapter => adapter)
      pm.to_inline_css
      doc = pm.processed_doc
      assert_equal '500', doc.at('table')['width']
      assert_equal '20', doc.at('td')['height']
    end
  end

  def test_empty_css_att
    html = <<-END_HTML
    <html> <head> <style>table { background-color: rgb(250, 250, 250); width: "550px"; } </style>
    <body>
    <table> <tr> <td> Test </td> </tr> </table>
    </body> </html>
    END_HTML

    pm = Premailer.new(html, :with_html_string => true, :rgb_to_hex_attributes => true, :remove_scripts => true, :adapter => :nokogiri)
    pm.to_inline_css
    doc = pm.processed_doc

    assert_match /<table[^>]+550px.+bgcolor="#FAFAFA"/, doc.at('table').to_s
  end

  def test_rgb_color
    html = <<-END_HTML
    <html> <head> <style>table { background-color: rgb(250, 250, 250); } </style>
    <body>
    <table> <tr> <td> Test </td> </tr> </table>
    </body> </html>
    END_HTML

    pm = Premailer.new(html, :with_html_string => true, :rgb_to_hex_attributes => true, :remove_scripts => true, :adapter => :nokogiri)
    pm.to_inline_css
    doc = pm.processed_doc
    assert_equal '#FAFAFA', doc.at('table')['bgcolor']
  end

  def test_rgb_color_with_preserve_style
    html = <<-END_HTML
    <html> <head> <style>table { background-color: rgb(250, 250, 250); } </style>
    <body>
    <table> <tr> <td> Test </td> </tr> </table>
    </body> </html>
    END_HTML

    pm = Premailer.new(html, :with_html_string => true, :preserve_style_attribute => true, :rgb_to_hex_attributes => true, :remove_scripts => true, :adapter => :nokogiri)
    pm.to_inline_css
    doc = pm.processed_doc
    assert_equal '#FAFAFA', doc.at('table')['bgcolor']
    assert_equal 'background-color: #FAFAFA;', doc.at('table')['style']
  end

  def test_non_rgb_color
    html = <<-END_HTML
    <html> <head> <style>table { background-color:red; } </style>
    <body>
    <table> <tr> <td> Test </td> </tr> </table>
    </body> </html>
    END_HTML

    pm = Premailer.new(html, :with_html_string => true, :rgb_to_hex_attributes => true, :adapter => :nokogiri)
    pm.to_inline_css
    doc = pm.processed_doc
    assert_equal 'red', doc.at('table')['bgcolor']
  end

  def test_blending_rgba_color
    html = <<-END_HTML
    <html> <head> <style>body { background-color: #c8c8c8; } table { background-color: rgba(100,100,100,0.50) } td { background-color: rgba(50,50,50,0.70)}</style>
    <body>
    <table> <tr> <td> Test </td> </tr> </table>
    </body> </html>
    END_HTML

    pm = Premailer.new(html, :with_html_string => true, :rgb_to_hex_attributes => true, :remove_scripts => true, :adapter => :nokogiri)
    pm.to_inline_css
    doc = pm.processed_doc
    assert_equal '#969696', doc.at('table')['bgcolor']
    assert_equal '#505050', doc.at('td')['bgcolor']
  end

  def test_include_link_tags_option
    local_setup('base.html', :adapter => :nokogiri, :include_link_tags => true)
    assert_match /1\.231/, @doc.at('body').attributes['style'].to_s
    assert_match /display: none/, @doc.at('.hide').attributes['style'].to_s

    local_setup('base.html', :adapter => :nokogiri, :include_link_tags => false)
    refute_match /1\.231/, @doc.at('body').attributes['style'].to_s
    assert_match /display: none/, @doc.at('.hide').attributes['style'].to_s
  end

  def test_include_style_tags_option
    local_setup('base.html', :adapter => :nokogiri, :include_style_tags => true)
    assert_match /1\.231/, @doc.at('body').attributes['style'].to_s
    assert_match /display: block/, @doc.at('#iphone').attributes['style'].to_s

    local_setup('base.html', :adapter => :nokogiri, :include_style_tags => false)
    assert_match /1\.231/, @doc.at('body').attributes['style'].to_s
    refute_match /display: block/, @doc.at('#iphone').attributes['style'].to_s
  end

  def test_input_encoding
    html_special_characters = "Ää, Öö, Üü"
    pm = Premailer.new(html_special_characters, :with_html_string => true, :adapter => :nokogiri, :input_encoding => "UTF-8")
    assert_match /#{html_special_characters}/, pm.to_inline_css
  end

  # output_encoding option should return HTML Entities when set to US-ASCII
  def test_output_encoding
    html_special_characters = "©"
    html_entities_characters = /&#169;/
    expected_html = /#{html_entities_characters}/
    pm = Premailer.new(html_special_characters, :output_encoding => "US-ASCII", :with_html_string => true, :adapter => :nokogiri, :input_encoding => "UTF-8");
    assert_match expected_html, pm.to_inline_css
  end

  def test_meta_encoding_downcase
    meta_encoding = '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">'
    expected_html = Regexp.new(Regexp.escape('<meta http-equiv="Content-Type" content="text/html; charset=utf-8">'), Regexp::IGNORECASE)
    pm = Premailer.new(meta_encoding, :with_html_string => true, :adapter => :nokogiri, :input_encoding => "utf-8")
    assert_match expected_html, pm.to_inline_css
  end

  def test_meta_encoding_upcase
    meta_encoding = '<meta http-equiv="Content-Type" content="text/html; charset=utf-8">'
    expected_html = Regexp.new(Regexp.escape('<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">'), Regexp::IGNORECASE)
    pm = Premailer.new(meta_encoding, :with_html_string => true, :adapter => :nokogiri, :input_encoding => "UTF-8")
    assert_match expected_html, pm.to_inline_css
  end

  def test_htmlentities
    html_entities = "&#8217;"
    pm = Premailer.new(html_entities, :with_html_string => true, :adapter => :nokogiri, :replace_html_entities => true)
    assert_match /'/, pm.to_inline_css
  end

  # If a line other than the first line in the html string begins with a URI
  # Premailer should not identify the html string as a URI. Otherwise the following
  # exception would be raised: ActionView::Template::Error: bad URI(is not URI?)
  def test_line_starting_with_uri_in_html_with_linked_css
    files_base = File.expand_path(File.dirname(__FILE__)) + '/files/'
    html_string = IO.read(File.join(files_base, 'html_with_uri.html'))

    premailer = Premailer.new(html_string, :with_html_string => true)
    premailer.to_inline_css
  end

  def test_empty_html_nokogiri
    html = ""
    css = "a:hover {color:red;}"

    pm = Premailer.new(html, :with_html_string => true, :css_string => css, :adapter => :nokogiri, input_encoding: 'UTF-8')
    pm.to_inline_css
  end

  def silence_stderr(&block)
    orig_stderr = $stderr
    $stderr = File.open(File::NULL, 'w')
    block.call
  ensure
    $stderr = orig_stderr
  end
end
