require 'test_helper'

class TestHtmlToPlainText < Test::Unit::TestCase
  include HtmlToPlainText

  def test_accents
    assert_plaintext 'cédille garçon à ñ', 'c&eacute;dille gar&#231;on &agrave; &ntilde;'
  end

  def test_trailing_whitespace
    assert_plaintext "text\ntext", "  \ttext\ntext\n"
  end

  def test_lists
    assert_plaintext "* item 1\n* item 2", "<li class='123'>item 1</li> <li>item 2</li>\n"
    assert_plaintext "* item 1\n* item 2\n* item 3", "<li>item 1</li> \t\n <li>item 2</li> <li> item 3</li>\n"
  end

  def assert_plaintext(out, raw, msg = nil)
    assert_equal out, convert_to_text(raw), msg
  end
end
