# encoding: UTF-8
require File.dirname(__FILE__) + '/helper'

class TestPremailer < Test::Unit::TestCase
  include WEBrick

  def test_accents
    local_setup

    assert_equal 'cédille cé &amp; garçon garçon à à', @doc.at('#specialchars').inner_html
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
