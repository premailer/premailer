# encoding: UTF-8
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

  def test_link_in_new_line_nokogiri
    html = 	"<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n<html>\n<head>\n<meta content='text/html; charset=utf-8' http-equiv='Content-Type'>\n<title>Test</title>\n<link href='/assets/mailer.css' rel='stylesheet' type='text/css'>\n</head>\n<body>\n<p class='description'>yay travis! \nhttp://travis-ci.org/#!/alexdunae/premailer</p>\n</body>\n</html>\n"
    premailer = Premailer.new(html, :with_html_string => true, :adapter => :nokogiri)
    premailer.to_inline_css
    assert_equal "yay travis! \nhttp://travis-ci.org/#!/alexdunae/premailer", premailer.processed_doc.at('p').inner_html
  end

  #def test_cyrillic_nokogiri_remote
  #  if RUBY_VERSION =~ /1.9/ 
  #    remote_setup('iso-8859-5.html', :adapter => :nokogiri) #, :encoding => 'iso-8859-5')
  #  	@premailer.to_inline_css
  #    assert_equal Encoding.find('ISO-8859-5'), @premailer.processed_doc.at('p').inner_html.encoding
  #  end
  #end

  # TODO: this passes when run from rake but not when run from:
  #  ruby -Itest test/test_premailer.rb -n test_special_characters_hpricot
  def test_special_characters_hpricot
    html = 	'<p>cédille c&eacute; & garçon gar&#231;on à &agrave; &nbsp; &amp;</p>'
    premailer = Premailer.new(html, :with_html_string => true, :adapter => :hpricot)
  	premailer.to_inline_css
    assert_equal 'c&eacute;dille c&eacute; &amp; gar&ccedil;on gar&ccedil;on &agrave; &agrave; &nbsp; &amp;', premailer.processed_doc.at('p').inner_html
  end
  
  def test_detecting_html
    [:nokogiri, :hpricot].each do |adapter|
      remote_setup('base.html', :adapter => adapter)
      assert !@premailer.is_xhtml?
    end
  end

  def test_detecting_xhtml
    [:nokogiri, :hpricot].each do |adapter|
      remote_setup('xhtml.html', :adapter => adapter)
      assert @premailer.is_xhtml?
    end
  end

  def test_self_closing_xhtml_tags
    [:nokogiri, :hpricot].each do |adapter|
      remote_setup('xhtml.html', :adapter => adapter)
      assert_match /<br[\s]*\/>/, @premailer.to_s
      assert_match /<br[\s]*\/>/, @premailer.to_inline_css
    end
  end

  def test_non_self_closing_html_tags
    [:nokogiri, :hpricot].each do |adapter|
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

    [:nokogiri, :hpricot].each do |adapter|
		  premailer = Premailer.new(html, :with_html_string => true, :link_query_string => qs, :adapter => adapter)
		  premailer.to_inline_css
	    assert_no_match /testing=123/, premailer.processed_doc.search('a').first.attributes['href'].to_s    
	  end
  end
  
  def test_escaping_strings
    local_setup
  
    str = %q{url("/images/test.png");}
    assert_equal("url(\'/images/test.png\');", Premailer.escape_string(str))
  end
  
  def test_importing_local_css
    # , :hpricot
    [:nokogiri].each do |adapter|
      local_setup('base.html', :adapter => adapter)

      # noimport.css (print stylesheet) sets body { background } to red
      assert_no_match /red/, @doc.at('body').attributes['style'].to_s
    
      # import.css sets .hide to { display: none } 
      assert_match /display: none/, @doc.at('#hide01').attributes['style'].to_s
    end
  end

  def test_importing_remote_css
    [:nokogiri, :hpricot].each do |adapter|
      remote_setup('base.html', :adapter => adapter)
  
      # noimport.css (print stylesheet) sets body { background } to red
      assert_no_match /red/, @doc.at('body')['style']
    
      # import.css sets .hide to { display: none } 
      assert_match /display: none/, @doc.at('#hide01')['style']
    end
  end

  def test_importing_css_as_string
    files_base = File.expand_path(File.dirname(__FILE__)) + '/files/'

    css_string = IO.read(File.join(files_base, 'import.css'))

    [:nokogiri, :hpricot].each do |adapter|
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
    assert premailer.local_uri?( '/path/' )
  end
  
  def test_initialize_can_accept_io_object
    [:nokogiri, :hpricot].each do |adapter|
      io = StringIO.new('hi mom')
      premailer = Premailer.new(io, :adapter => adapter)
      assert_match /hi mom/, premailer.to_inline_css
    end
  end
  
  def test_initialize_can_accept_html_string
    [:nokogiri, :hpricot].each do |adapter|
      premailer = Premailer.new('<p>test</p>', :with_html_string => true, :adapter => adapter)
      assert_match /test/, premailer.to_inline_css
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

    [:nokogiri, :hpricot].each do |adapter|
  		pm = Premailer.new(html, :with_html_string => true, :remove_ids => true, :adapter => adapter)
      pm.to_inline_css
      doc = pm.processed_doc
  	  assert_nil doc.at('#remove')
  	  assert_nil doc.at('#keep')
  	  hashed_id = doc.at('a')['href'][1..-1]
  	  assert_not_nil doc.at("\##{hashed_id}")
  	end
  end
  
  def test_carriage_returns_as_entities
    html = <<-html
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html>
    <body>\n\r<p>test</p>\n\r<p>test</p>
    </body></html>
    html

    [:nokogiri, :hpricot].each do |adapter|
      pm = Premailer.new(html, :with_html_string => true, :adapter => adapter)
      assert_match /\r/, pm.to_inline_css
    end
  end
  
  
  def test_advanced_selectors
    remote_setup('base.html', :adapter => :nokogiri)
    assert_match /italic/, @doc.at('h2 + h3')['style']
    assert_match /italic/, @doc.at('p[attr~=quote]')['style']
    assert_match /italic/, @doc.at('ul li:first-of-type')['style']
    
    remote_setup('base.html', :adapter => :hpricot)
    assert_match /italic/, @doc.at('p[@attr~="quote"]')['style']
    assert_match /italic/, @doc.at('ul li:first-of-type')['style']
  end

  def test_premailer_related_attributes
    html = <<END_HTML
    <html> <head> <style>table { -premailer-width: 500; } td { -premailer-height: 20}; </style>
    <body>
		<table> <tr> <td> Test </td> </tr> </table>
		</body> </html>
END_HTML

    [:nokogiri, :hpricot].each do |adapter|
  		pm = Premailer.new(html, :with_html_string => true, :adapter => adapter)
      pm.to_inline_css
      doc = pm.processed_doc
  	  assert_equal '500', doc.at('table')['width']
  	  assert_equal '20', doc.at('td')['height']
  	end
  end

  def test_include_link_tags_option
    local_setup('base.html', :adapter => :nokogiri, :include_link_tags => true)
    assert_match /1\.231/, @doc.at('body').attributes['style'].to_s
    assert_match /display: none/, @doc.at('.hide').attributes['style'].to_s

    local_setup('base.html', :adapter => :nokogiri, :include_link_tags => false)
    assert_no_match /1\.231/, @doc.at('body').attributes['style'].to_s
    assert_match /display: none/, @doc.at('.hide').attributes['style'].to_s
  end

  def test_include_style_tags_option
    local_setup('base.html', :adapter => :nokogiri, :include_style_tags => true)
    assert_match /1\.231/, @doc.at('body').attributes['style'].to_s
    assert_match /display: block/, @doc.at('#iphone').attributes['style'].to_s

    local_setup('base.html', :adapter => :nokogiri, :include_style_tags => false)
    assert_match /1\.231/, @doc.at('body').attributes['style'].to_s
    assert_no_match /display: block/, @doc.at('#iphone').attributes['style'].to_s
  end

  def test_input_encoding
    html_special_characters = "Ää, Öö, Üü".encode("UTF-8")
    expected_html = "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">\n<html><body><p>" + html_special_characters + "</p></body></html>\n"
    pm = Premailer.new(html_special_characters, :with_html_string => true, :adapter => :nokogiri, :input_encoding => "UTF-8")
    assert_equal expected_html, pm.to_inline_css
  end

  def test_htmlentities
    html_entities = "&#8217;"
    expected_html = "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">\n<html><body><p>'</p></body></html>\n"
    pm = Premailer.new(html_entities, :with_html_string => true, :adapter => :nokogiri, :replace_html_entities => true)
    assert_equal expected_html, pm.to_inline_css
  end
end
