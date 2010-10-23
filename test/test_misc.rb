# encoding: UTF-8
require File.dirname(__FILE__) + '/helper'

# Random tests for specific issues.
#
# The test suite will be cleaned up at some point soon.
class TestMisc < Test::Unit::TestCase
  include WEBrick

  # in response to http://github.com/alexdunae/premailer/issues#issue/4
  def test_parsing_extra_quotes
    io = StringIO.new('<p></p>
    <h3 "id="WAR"><a name="WAR"></a>Writes and Resources</h3>
    <table></table>')
    premailer = Premailer.new(io)
    assert_match /<h3>[\s]*<a name="WAR">[\s]*<\/a>[\s]*Writes and Resources[\s]*<\/h3>/i, premailer.to_inline_css
  end
end
