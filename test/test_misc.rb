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
  
  # in response to https://github.com/alexdunae/premailer/issues#issue/7
  def test_parsing_bad_markup_around_tables
    html = <<END_HTML
    <html>
    <style type="text/css"> 
      .style3 { font-size: xx-large; }
      .style5 { background-color: #000080; } 
    </style>
		<tr>
						<td valign="top" class="style3">
						<!-- MSCellType="ContentHead" -->
						<strong>PROMOCION CURSOS PRESENCIALES</strong></td>
						<strong>
						<td valign="top" style="height: 125px" class="style5">
						<!-- MSCellType="DecArea" -->
						<img alt="" src="../../images/CertisegGold.GIF" width="608" height="87" /></td>
		</tr>
END_HTML

		premailer = Premailer.new(html, :with_html_string => true)
		premailer.to_inline_css
	  assert_match /font-size: xx-large/, premailer.processed_doc.search('.style3').first.attributes['style'].to_s
	  assert_match /background-color: #000080/, premailer.processed_doc.search('.style5').first.attributes['style'].to_s		
  end
end
