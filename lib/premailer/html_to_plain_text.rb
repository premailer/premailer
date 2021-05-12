require 'htmlentities'

# Support functions for Premailer
module HtmlToPlainText
  # Returns the text in UTF-8 format with all HTML tags removed
  #
  # HTML content can be omitted from the output by surrounding it in the following comments:
  #
  # <!-- start text/html -->
  # <!-- end text/html -->
  #
  # TODO: add support for DL, OL
  # TODO: this is not safe and needs a real html parser to work
  def convert_to_text(html, line_length = 65, _from_charset = 'UTF-8')
    txt = html

    # strip text ignored html. Useful for removing
    # headers and footers that aren't needed in the
    # text version
    txt.gsub!(%r{<!-- start text/html -->.*?<!-- end text/html -->}m, '')

    # replace images with their alt attributes
    # for img tags with "" for attribute quotes
    # with or without closing tag
    # eg. the following formats:
    # <img alt="" />
    # <img alt="">
    txt.gsub!(/<img[^>]+?alt="([^"]*)"[^>]*>/i, '\1')

    # for img tags with '' for attribute quotes
    # with or without closing tag
    # eg. the following formats:
    # <img alt='' />
    # <img alt=''>
    txt.gsub!(/<img[^>]+?alt='([^']*)'[^>]*>/i, '\1')

    # remove script tags and content
    txt.gsub!(%r{<script.*?/script>}m, '')

    # links
    txt.gsub!(%r{<a[\s]+([^>]+)>((?:.(?!\</a\>))*.)</a>}im) do |s|
      text = Regexp.last_match(2).strip
      href = nil

      ["'", '"'].each do |quote_char|
        match = /href=#{quote_char}(mailto:)?([^#{quote_char}]*)#{quote_char}/.match(s)
        href = match[2] unless match.nil?
      end

      if text.empty?
        ''
      elsif href.nil? || text.strip.downcase == href.strip.downcase
        text.strip
      else
        text.strip + ' ( ' + href.strip + ' )'
      end
    end

    # handle headings (H1-H6)
    txt.gsub!(%r{(</h[1-6]>)}i, "\n\\1") # move closing tags to new lines
    txt.gsub!(%r{[\s]*<h([1-6]+)[^>]*>[\s]*(.*)[\s]*</h[1-6]+>}i) do |_s|
      hlevel = Regexp.last_match(1).to_i

      htext = Regexp.last_match(2)
      htext.gsub!(%r{<br[\s]*/?>}i, "\n") # handle <br>s
      htext.gsub!(%r{</?[^>]*>}i, '') # strip tags

      # determine maximum line length
      hlength = 0
      htext.each_line { |l| llength = l.strip.length; hlength = llength if llength > hlength }
      hlength = line_length if hlength > line_length

      htext = case hlevel
              when 1   # H1, asterisks above and below
                ('*' * hlength) + "\n" + htext + "\n" + ('*' * hlength)
              when 2   # H1, dashes above and below
                ('-' * hlength) + "\n" + htext + "\n" + ('-' * hlength)
              else # H3-H6, dashes below
                htext + "\n" + ('-' * hlength)
              end

      "\n\n" + htext + "\n\n"
    end

    # wrap spans
    txt.gsub!(%r{(</span>)[\s]+(<span)}mi, '\1 \2')

    # lists -- TODO: should handle ordered lists
    txt.gsub!(/[\s]*(<li[^>]*>)[\s]*/i, '* ')
    # list not followed by a newline
    txt.gsub!(%r{</li>[\s]*(?![\n])}i, "\n")

    # paragraphs and line breaks
    txt.gsub!(%r{</p>}i, "\n\n")
    txt.gsub!(%r{<br[/ ]*>}i, "\n")

    # strip remaining tags
    txt.gsub!(%r{</?[^>]*>}, '')

    # decode HTML entities
    he = HTMLEntities.new
    txt = he.decode(txt)

    # word wrap
    txt = word_wrap(txt, line_length)

    # remove linefeeds (\r\n and \r -> \n)
    txt.gsub!(/\r\n?/, "\n")

    # strip extra spaces
    txt.gsub!(/[ \t]*\302\240+[ \t]*/, ' ') # non-breaking spaces -> spaces
    txt.gsub!(/\n[ \t]+/, "\n") # space at start of lines
    txt.gsub!(/[ \t]+\n/, "\n") # space at end of lines

    # no more than two consecutive newlines
    txt.gsub!(/[\n]{3,}/, "\n\n")

    # the word messes up the parens
    txt.gsub!(/\(([ \n])(http[^)]+)([\n ])\)/) do |_s|
      (Regexp.last_match(1) == "\n" ? Regexp.last_match(1) : '') + '( ' + Regexp.last_match(2) + ' )' + (Regexp.last_match(3) == "\n" ? Regexp.last_match(1) : '')
    end

    txt.strip
  end

  # Taken from Rails' word_wrap helper (http://api.rubyonrails.org/classes/ActionView/Helpers/TextHelper.html#method-i-word_wrap)
  def word_wrap(txt, line_length)
    txt.split("\n").collect do |line|
      line.length > line_length ? line.gsub(/(.{1,#{line_length}})(\s+|$)/, "\\1\n").strip : line
    end * "\n"
  end
end
