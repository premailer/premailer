require 'test_helper'

class TestPremailer < Test::Unit::TestCase
  def setup
    base_file = File.dirname(__FILE__) + '/files/base.html'  
    premailer = Premailer.new(base_file)
    premailer.to_inline_css

    @doc = premailer.processed_doc
  end

  def test_accents
    assert_equal(
      'cédille c&eacute; garçon gar&#231;on à &agrave;', 
      @doc.at('#accents').inner_html
    )   
  end
  
  def test_escaping_strings
    str = %q{url("/images/test.png");}
    assert_equal("url(\'/images/test.png\');", Premailer.escape_string(str))

    str = %q{url("/images/\"test.png");}
    assert_equal("url(\'/images/\'test.png\');", Premailer.escape_string(str))

    str = %q{url('/images/\"test.png');}
    assert_equal("url(\'/images/\'test.png\');", Premailer.escape_string(str))
  end
end
