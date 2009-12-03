require 'text/reform'
require 'htmlentities'

# Support functions for Premailer
module HtmlToPlainText

  # Returns the text in UTF-8 format with all HTML tags removed
  #
  # TODO:
  #  - add support for DL, OL
  def convert_to_text(html, line_length = 65, from_charset = 'UTF-8')
    r = Text::Reform.new(:trim => true, 
                         :squeeze => false, 
                         :break => Text::Reform.break_wrap)

    txt = html
    
    # decode HTML entities
    he = HTMLEntities.new
    txt = he.decode(txt)

    # handle headings (H1-H6)
    txt.gsub!(/[ \t]*<h([0-9]+)[^>]*>(.*)<\/h[0-9]+>/i) do |s|
      hlevel = $1.to_i
      # cleanup text inside of headings
      htext = $2.gsub(/<\/?[^>]*>/i, '').strip
      hlength = (htext.length > line_length ? 
                  line_length : 
                  htext.length)

      case hlevel
        when 1   # H1, asterisks above and below
          ('*' * hlength) + "\n" + htext + "\n" + ('*' * hlength) + "\n"
        when 2   # H1, dashes above and below
          ('-' * hlength) + "\n" + htext + "\n" + ('-' * hlength) + "\n"
        else     # H3-H6, dashes below
          htext + "\n" + ('-' * htext.length) + "\n"
      end
    end

    # links
    txt.gsub!(/<a.*href=\"([^\"]*)\"[^>]*>(.*)<\/a>/i) do |s|
      $2.strip + ' ( ' + $1.strip + ' )'
    end

    # lists -- TODO: should handle ordered lists
    txt.gsub!(/[\s]*(<li[^>]*>)[\s]*/i, '* ')
    # list not followed by a newline
    txt.gsub!(/<\/li>[\s]*(?![\n])/i, "\n")
    
    # paragraphs and line breaks
    txt.gsub!(/<\/p>/i, "\n\n")
    txt.gsub!(/<br[\/ ]*>/i, "\n")
    
    # strip remaining tags
    txt.gsub!(/<\/?[^>]*>/, '')

    # wrap text
    txt = r.format(('[' * line_length), txt)
    
    # remove linefeeds (\r\n and \r -> \n)
    txt.gsub!(/\r\n?/, "\n")
    
    # strip extra spaces
    txt.gsub!(/\302\240+/, " ") # non-breaking spaces -> spaces
    txt.gsub!(/\n[ \t]+/, "\n") # space at start of lines
    txt.gsub!(/[ \t]+\n/, "\n") # space at end of lines

    # no more than two consecutive newlines
    txt.gsub!(/[\n]{3,}/, "\n\n")

    txt.strip
  end
end
