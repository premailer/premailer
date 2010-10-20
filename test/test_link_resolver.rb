require File.dirname(__FILE__) + '/helper'

class TestLinkResolver < Test::Unit::TestCase
  def test_resolving_urls_from_string
    ['test.html', '/test.html', './test.html', 
     'test/../test.html', 'test/../test/../test.html'].each do |q|
      assert_equal 'http://example.com/test.html', Premailer.resolve_link(q, 'http://example.com/'), q
    end

    assert_equal 'https://example.net:80/~basedir/test.html?var=1#anchor', Premailer.resolve_link('test/../test/../test.html?var=1#anchor', 'https://example.net:80/~basedir/')
  end

  def test_resolving_urls_from_uri
    base_uri = URI.parse('http://example.com/')
    ['test.html', '/test.html', './test.html', 
     'test/../test.html', 'test/../test/../test.html'].each do |q|
      assert_equal 'http://example.com/test.html', Premailer.resolve_link(q, base_uri), q
    end

    base_uri = URI.parse('https://example.net:80/~basedir/')
    assert_equal 'https://example.net:80/~basedir/test.html?var=1#anchor', Premailer.resolve_link('test/../test/../test.html?var=1#anchor', base_uri)
    
    # base URI with a query string
    base_uri = URI.parse('http://example.com/dir/index.cfm?newsletterID=16')
    assert_equal 'http://example.com/dir/index.cfm?link=15', Premailer.resolve_link('?link=15', base_uri)
    
    # URI preceded by a space
    base_uri = URI.parse('http://example.com/')
    assert_equal 'http://example.com/path', Premailer.resolve_link(' path', base_uri)
  end

  def test_resolving_urls_in_doc
    base_file = File.dirname(__FILE__) + '/files/base.html'
    base_url = 'https://my.example.com:8080/test-path.html'
    premailer = Premailer.new(base_file, :base_url => base_url)
    premailer.to_inline_css
    pdoc = premailer.processed_doc
    doc = premailer.doc

    # unchanged links
    ['#l02', '#l03', '#l05', '#l06', '#l07', '#l08', 
     '#l09', '#l10', '#l11', '#l12', '#l13'].each do |link_id|
      assert_equal doc.at(link_id).attributes['href'], pdoc.at(link_id).attributes['href'], link_id
    end
    
    assert_equal 'https://my.example.com:8080/', pdoc.at('#l01').attributes['href'].to_s
    assert_equal 'https://my.example.com:8080/images/', pdoc.at('#l04').attributes['href'].to_s
  end
end
