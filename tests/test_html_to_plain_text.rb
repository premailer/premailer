require 'test_helper'

class TestHtmlToPlainText < Test::Unit::TestCase
  include HtmlToPlainText

  def test_accents
    assert_plaintext 'cédille garçon à ñ', 'c&eacute;dille gar&#231;on &agrave; &ntilde;'
  end

  def test_stripping_whitespace
    assert_plaintext "text\ntext", "  \ttext\ntext\n"
  end

  def test_lists
    assert_plaintext "* item 1\n* item 2", "<li class='123'>item 1</li> <li>item 2</li>\n"
    assert_plaintext "* item 1\n* item 2\n* item 3", "<li>item 1</li> \t\n <li>item 2</li> <li> item 3</li>\n"
  end
  
  def test_stripping_html
    assert_plaintext 'test text', "<p class=\"123'45 , att\" att=tester>test <span class='te\"st'>text</span>\n"
  end

  def test_paragraphs
    assert_plaintext "Test text\n\nTest text", "<p>Test text</p><p>Test text</p>"
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
