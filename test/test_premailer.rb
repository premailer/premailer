# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__)) + '/helper'

class TestPremailer < Test::Unit::TestCase
  include WEBrick

  def test_preserving_special_characters
    html = 	'<p>cédille c&eacute; & garçon gar&#231;on à &agrave; &nbsp; &amp;</p>'
    premailer = Premailer.new(html, :with_html_string => true)
		premailer.to_inline_css
    assert_equal 'cédille c&eacute; & garçon gar&#231;on à &agrave; &nbsp; &amp;', premailer.processed_doc.at('p').inner_html
  end
  
  def test_detecting_html
    remote_setup('base.html')
    assert !@premailer.is_xhtml?
  end

  def test_detecting_xhtml
    remote_setup('xhtml.html')
    assert @premailer.is_xhtml?
  end

  def test_self_closing_xhtml_tags
    remote_setup('xhtml.html')
    assert_match /<br[\s]*\/>/, @premailer.to_s
    assert_match /<br[\s]*\/>/, @premailer.to_inline_css
  end

  def test_non_self_closing_html_tags
    remote_setup('html4.html')
    assert_match /<br>/, @premailer.to_s
    assert_match /<br>/, @premailer.to_inline_css
  end
  
  def test_mailtos_with_query_strings
    html = <<END_HTML
    <html>
		<a href="mailto:info@example.com?subject=Programmübersicht&amp;body=Lorem ipsum dolor sit amet.">Test</a>
		</html>
END_HTML

    qs = 'testing=123'

		premailer = Premailer.new(html, :with_html_string => true, :link_query_string => qs)
		premailer.to_inline_css
	  assert_no_match /testing=123/, premailer.processed_doc.search('a').first.attributes['href'].to_s    
  end
  
  def test_escaping_strings
    local_setup
  
    str = %q{url("/images/test.png");}
    assert_equal("url(\'/images/test.png\');", Premailer.escape_string(str))
  end
  
  def test_importing_local_css
    local_setup

    # noimport.css (print stylesheet) sets body { background } to red
    assert_no_match /red/, @doc.at('body').attributes['style'].to_s
    
    # import.css sets .hide to { display: none } 
    assert_match /display: none/, @doc.at('#hide01').attributes['style'].to_s
  end

  def test_importing_remote_css
    remote_setup
  
    # noimport.css (print stylesheet) sets body { background } to red
    assert_no_match /red/, @doc.at('body').attributes['style']
    
    # import.css sets .hide to { display: none } 
    assert_match /display: none/, @doc.at('#hide01').attributes['style']
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
    io = StringIO.new('hi mom')
    premailer = Premailer.new(io)
    assert_match premailer.to_inline_css, /hi mom/
  end
  
  def test_initialize_can_accept_html_string
    premailer = Premailer.new('<p>test</p>', :with_html_string => true)
    assert_match premailer.to_inline_css, /test/
  end

protected
  def local_setup(f = 'base.html', opts = {})
    base_file = File.expand_path(File.dirname(__FILE__)) + '/files/' + f
    premailer = Premailer.new(base_file, opts)
    premailer.to_inline_css
    @doc = premailer.processed_doc
  end
  
  def remote_setup(f = 'base.html', opts = {})
    # from http://nullref.se/blog/2006/5/17/testing-with-webrick
    uri_base = 'http://localhost:12000'
    www_root = File.expand_path(File.dirname(__FILE__)) + '/files/'

    @server_thread = Thread.new do
      s = WEBrick::HTTPServer.new(:Port => 12000, :DocumentRoot => www_root, :Logger => Log.new(nil, BasicLog::ERROR), :AccessLog => [])
      port = s.config[:Port]
      begin
        s.start
      ensure
        s.shutdown
      end
    end

    sleep 1 # ensure the server has time to load
    
    @premailer = Premailer.new(uri_base + "/#{f}", opts)
    @premailer.to_inline_css
    @doc = @premailer.processed_doc
  end

  def teardown
    if @server_thread
      @server_thread.kill
      @server_thread.join(5)
      @server_thread = nil
    end
  end
end
