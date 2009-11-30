require 'test_helper'

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
  end
end
