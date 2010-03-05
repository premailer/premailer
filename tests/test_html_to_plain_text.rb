require File.dirname(__FILE__) + '/test_helper'

class TestHtmlToPlainText < Test::Unit::TestCase
  include HtmlToPlainText

  def test_accents
    assert_plaintext 'cédille garçon à ñ', 'c&eacute;dille gar&#231;on &agrave; &ntilde;'
  end

  def test_stripping_whitespace
    assert_plaintext "text\ntext", "  \ttext\ntext\n"
    assert_plaintext "a\na", "  \na \n a \t"
    assert_plaintext "a\n\na", "  \na \n\t \n \n a \t"
    assert_plaintext "test text", "test text&nbsp;"
  end

  def test_line_breaks
    assert_plaintext "Test text\nTest text", "Test text\r\nTest text"
    assert_plaintext "Test text\nTest text", "Test text\rTest text"
  end

  def test_lists
    assert_plaintext "* item 1\n* item 2", "<li class='123'>item 1</li> <li>item 2</li>\n"
    assert_plaintext "* item 1\n* item 2\n* item 3", "<li>item 1</li> \t\n <li>item 2</li> <li> item 3</li>\n"
  end
  
  def test_stripping_html
    assert_plaintext 'test text', "<p class=\"123'45 , att\" att=tester>test <span class='te\"st'>text</span>\n"
  end

  def test_paragraphs_and_breaks
    assert_plaintext "Test text\n\nTest text", "<p>Test text</p><p>Test text</p>"
    assert_plaintext "Test text\n\nTest text", "\n<p>Test text</p>\n\n\n\t<p>Test text</p>\n"
    assert_plaintext "Test text\nTest text", "\n<p>Test text<br/>Test text</p>\n"
    assert_plaintext "Test text\nTest text", "\n<p>Test text<br> \tTest text<br></p>\n"
    assert_plaintext "Test text\n\nTest text", "Test text<br><BR />Test text"
  end
  
  def test_headings
    assert_plaintext "****\nTest\n****", "<h1>Test</h1>"
    assert_plaintext "****\nTest\n****", "\t<h1>\nTest</h1> "
    assert_plaintext "***********\nTest line 1\nTest 2\n***********", "\t<h1>\nTest line 1<br>Test 2</h1> "
    assert_plaintext "****\nTest\n****\n\n****\nTest\n****", "<h1>Test</h1> <h1>Test</h1>"
    assert_plaintext "----\nTest\n----", "<h2>Test</h2>"
    assert_plaintext "Test\n----", "<h3> <span class='a'>Test </span></h3>"
  end

  def test_links
    # basic
    assert_plaintext 'Link ( http://example.com/ )', '<a href="http://example.com/">Link</a>'
    
    # nested html
    assert_plaintext 'Link ( http://example.com/ )', '<a href="http://example.com/"><span class="a">Link</span></a>'
    
    # complex link
    assert_plaintext 'Link ( http://example.com:80/~user?aaa=bb&c=d,e,f#foo )', '<a href="http://example.com:80/~user?aaa=bb&amp;c=d,e,f#foo">Link</a>'
    
    # attributes
    assert_plaintext 'Link ( http://example.com/ )', '<a title=\'title\' href="http://example.com/">Link</a>'
    
    # spacing
    assert_plaintext 'Link ( http://example.com/ )', '<a href="   http://example.com/ "> Link </a>'
    
    # merge links
    assert_plaintext 'Link ( %%LINK%% )', '<a href="%%LINK%%">Link</a>'
    assert_plaintext 'Link ( [LINK] )', '<a href="[LINK]">Link</a>'
    assert_plaintext 'Link ( {LINK} )', '<a href="{LINK}">Link</a>'
  end

  def assert_plaintext(out, raw, msg = nil)
    assert_equal out, convert_to_text(raw), msg
  end
end
