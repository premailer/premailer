require File.dirname(__FILE__) + '/test_helper'
require 'webrick'

class TestPremailer < Test::Unit::TestCase
  include WEBrick

  def test_accents
    local_setup

    assert_equal 'cédille c&eacute; garçon gar&#231;on à &agrave;', @doc.at('#accents').inner_html
  end
  
  def test_escaping_strings
    local_setup
  
    str = %q{url("/images/test.png");}
    assert_equal("url(\'/images/test.png\');", Premailer.escape_string(str))
  end
  
  def test_importing_local_css
    flunk
    local_setup
  
    # noimport.css (print stylesheet) sets body { background } to red
    assert_no_match /red/, @doc.at('body').attributes['style']
    
    # import.css sets .hide to { display: none } 
    assert_match /display: none/, @doc.at('#hide01').attributes['style']
  end

  def test_importing_remote_css
    flunk
    remote_setup
  
    # noimport.css (print stylesheet) sets body { background } to red
    assert_no_match /red/, @doc.at('body').attributes['style']
    
    # import.css sets .hide to { display: none } 
    assert_match /display: none/, @doc.at('#hide01').attributes['style']
  end


  def test_related_attributes
    local_setup
    
    # h1 { text-align: center; }
    assert_equal 'center', @doc.at('h1')['align']
    
    # td { vertical-align: top; }
    assert_equal 'top', @doc.at('td')['valign']
    
    # p { vertical-align: top; } -- not allowed
    assert_nil @doc.at('p')['valign']
    
    # no align attr is specified for <p> elements, so it should not appear
    assert_nil @doc.at('p.unaligned')['align']
    
    # .contact { background: #9EC03B url("contact_bg.png") repeat 0 0; }
    assert_equal '#9EC03B', @doc.at('td.contact')['bgcolor']
    
    # body { background-color: #9EBF00; }
    assert_equal '#9EBF00', @doc.at('body')['bgcolor']
  end

  def test_merging_cellpadding
    flunk
    local_setup('cellpadding.html', {:prefer_cellpadding => true})
    assert_equal '0', @doc.at('#t1')['cellpadding']
    assert_match /padding\:/i, @doc.at('#t1 td')['style']

    assert_equal '5', @doc.at('#t2')['cellpadding']
    assert_no_match /padding\:/i, @doc.at('#t2 td')['style']
    
    assert_nil @doc.at('#t3')['cellpadding']
    assert_match /padding\:/i, @doc.at('#t3 td')['style']

    assert_nil @doc.at('#t4')['cellpadding']
    assert_match /padding\:/i, @doc.at('#t4a')['style']
    assert_match /padding\:/i, @doc.at('#t4b')['style']
  end
  
  def test_preserving_media_queries
    local_setup
    assert_match /display\: none/i, @doc.at('#iphone')['style']
  end
  
  def test_initialize_can_accept_io_object
    io = StringIO.new('hi mom')
    premailer = Premailer.new(io)
    assert_equal premailer.to_inline_css, 'hi mom'
  end

protected
  def local_setup(f = 'base.html', opts = {})
    base_file = File.dirname(__FILE__) + '/files/' + f
    premailer = Premailer.new(base_file, opts)
    premailer.to_inline_css
    @doc = premailer.processed_doc
  end
  
  def remote_setup(opts = {})
    # from http://nullref.se/blog/2006/5/17/testing-with-webrick
    uri_base = 'http://localhost:12000'
    www_root = File.dirname(__FILE__) + '/files/'

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
    
    premailer = Premailer.new(uri_base + '/base.html', opts)
    premailer.to_inline_css
    @doc = premailer.processed_doc
  end

  def teardown
    if @server_thread
      @server_thread.kill
      @server_thread.join(5)
      @server_thread = nil
    end
  end
end
