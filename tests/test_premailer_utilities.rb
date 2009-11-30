require 'test_helper'

class TestPremailerUtilities < Test::Unit::TestCase
  def test_escaping_strings
    str = %q{url("/images/test.png");}
    assert "url(\'/images/test.png\');", Premailer.escape_string(str)

    str = %q{url("/images/\"test.png");}
    assert "url(\'/images/\'test.png\');", Premailer.escape_string(str)

    str = %q{url('/images/\"test.png');}
    assert "url(\'/images/\'test.png\');", Premailer.escape_string(str)
  end
end
