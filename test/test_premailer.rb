# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__)) + '/helper'

class TestPremailer < Test::Unit::TestCase
  include WEBrick

  def setup
    # from http://nullref.se/blog/2006/5/17/testing-with-webrick
    @uri_base = "http://localhost:12000"
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
  end

  def test_preserving_special_characters
    html = 	'<p>cédille c&eacute; & garçon gar&#231;on à &agrave; &nbsp; &amp;</p>'
    [:hpricot, :nokogiri].each do |adapter|
      premailer = Premailer.new(html, :with_html_string => true, :adapter => adapter)
    	premailer.to_inline_css
      assert_equal 'cédille c&eacute; & garçon gar&#231;on à &agrave; &nbsp; &amp;', premailer.processed_doc.at('p').inner_html, "adapter: #{adapter}"
    end
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
    [:nokogiri, :hpricot].each do |adapter|
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

protected
  def local_setup(f = 'base.html', opts = {})
    base_file = File.expand_path(File.dirname(__FILE__)) + '/files/' + f
    premailer = Premailer.new(base_file, opts)
    premailer.to_inline_css
    @doc = premailer.processed_doc
  end
  
  def remote_setup(f = 'base.html', opts = {})
    # increment the port number for testing multiple adapters  
    @premailer = Premailer.new(@uri_base + "/#{f}", opts)
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
