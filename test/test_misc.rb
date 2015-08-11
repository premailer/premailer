# encoding: UTF-8
require File.expand_path(File.dirname(__FILE__)) + '/helper'

# Random tests for specific issues.
#
# The test suite will be cleaned up at some point soon.
class TestMisc < Premailer::TestCase

  # in response to http://github.com/alexdunae/premailer/issues#issue/4
  #
  # NB: 2010-11-16 -- after reverting to Hpricot this test can no longer pass.
  # It's too much of an edge case to get any dev time.
  def test_parsing_extra_quotes
    io = StringIO.new('<p></p>
    <h3 "id="WAR"><a name="WAR"></a>Writes and Resources</h3>
    <table></table>')
    premailer = Premailer.new(io, :adapter => :nokogiri)
    assert_match /<h3>[\s]*<a name="WAR">[\s]*<\/a>[\s]*Writes and Resources[\s]*<\/h3>/i, premailer.to_inline_css
  end

  def test_styles_in_the_body
    html = <<END_HTML
    <html>
    <body>
    <style type="text/css"> p { color: red; } </style>
		<p>Test</p>
		</body>
		</html>
END_HTML

    premailer = Premailer.new(html, :with_html_string => true)
    premailer.to_inline_css

    assert_match /color\: red/i,  premailer.processed_doc.at('p')['style']
  end

  def test_commented_out_styles_in_the_body
    html = <<END_HTML
    <html>
    <body>
    <style type="text/css"> <!-- p { color: red; } --> </style>
		<p>Test</p>
		</body>
		</html>
END_HTML

    premailer = Premailer.new(html, :with_html_string => true)
    premailer.to_inline_css

    assert_match /color\: red/i,  premailer.processed_doc.at('p')['style']
  end

  def test_not_applying_styles_to_the_head
    html = <<END_HTML
    <html>
    <head>
    <title>Title</title>
    <style type="text/css"> * { color: red; } </style>
    </head>
    <body>
		<p><a>Test</a></p>
		</body>
		</html>
END_HTML

    [:nokogiri, :hpricot].each do |adapter|
      premailer = Premailer.new(html, :with_html_string => true, :adapter => adapter)
      premailer.to_inline_css

      h = premailer.processed_doc.at('head')
      assert_nil h['style']

      t = premailer.processed_doc.at('title')
      assert_nil t['style']
    end
  end

  def test_multiple_identical_ids
    html = <<-END_HTML
    <html>
    <head>
    <style type="text/css"> #the_id { color: red; } </style>
    </head>
    <body>
		<p id="the_id">Test</p>
		<p id="the_id">Test</p>
		</body>
		</html>
    END_HTML

    premailer = Premailer.new(html, :with_html_string => true)
    premailer.to_inline_css
    premailer.processed_doc.search('p').each do |el|
      assert_match /red/i, el['style']
    end
  end

  def test_preserving_styles
    html = <<END_HTML
    <html>
    <head>
    <link rel="stylesheet" href="#"/>
    <style type="text/css"> a:hover { color: red; } </style>
    </head>
    <body>
		<p><a>Test</a></p>
		</body>
		</html>
END_HTML
    [:nokogiri, :hpricot].each do |adapter|
      premailer = Premailer.new(html, :with_html_string => true, :preserve_styles => true,  :adapter => adapter)
      premailer.to_inline_css
      assert_equal 1, premailer.processed_doc.search('head link').length
      assert_equal 1, premailer.processed_doc.search('head style').length

      premailer = Premailer.new(html, :with_html_string => true, :preserve_styles => false, :adapter => adapter)
      premailer.to_inline_css
      assert_nil premailer.processed_doc.at('body link')

      # should be preserved as unmergeable

      assert_match /color: red/i, premailer.processed_doc.at('body style').inner_html

      assert_match /a:hover/i, premailer.processed_doc.at('style').inner_html

    end
  end

  def test_unmergable_rules
    html = <<END_HTML
    <html> <head> <style type="text/css"> a { color:blue; } a:hover { color: red; } </style> </head>
		<p><a>Test</a></p>
		</body> </html>
END_HTML

    premailer = Premailer.new(html, :with_html_string => true, :verbose => true)
    premailer.to_inline_css

    # blue should be inlined
    assert_no_match /a\:hover[\s]*\{[\s]*color\:[\s]*blue[\s]*;[\s]*\}/i, premailer.processed_doc.at('body style').inner_html
    # red should remain in <style> block
    assert_match /a\:hover[\s]*\{[\s]*color\:[\s]*red;[\s]*\}/i, premailer.processed_doc.at('body style').inner_html
  end

  def test_unmergable_media_queries
    html = <<END_HTML
    <html> <head>
    <style type="text/css">
    a { color: blue; }
    @media (min-width:500px) {
      a { color: red; }
    }
    @media screen and (orientation: portrait) {
      a { color: green; }
    }
    </style>
    </head>
    <body>
    <p><a>Test</a></p>
    </body> </html>
END_HTML

    [:nokogiri, :hpricot].each do |adapter|
      puts "------- Testing adapter #{adapter}"
      premailer = Premailer.new(html, :with_html_string => true, :adapter => adapter)
      puts premailer.to_inline_css

      style_tag = premailer.processed_doc.at('body style')
      assert style_tag, "#{adapter} failed to add a body style tag"

      style_tag_contents = style_tag.inner_html

      assert_equal "color: blue", premailer.processed_doc.at('a').attributes['style'].to_s,
                   "#{adapter}: Failed to inline the default style"
      assert_match /@media \(min-width:500px\) \{.*?a \{.*?color: red;.*?\}.*?\}/m, style_tag_contents,
                   "#{adapter}: Failed to add media query with no type to style"
      assert_match /@media screen and \(orientation: portrait\) \{.*?a \{.*?color: green;.*?\}.*?\}/m, style_tag_contents,
                   "#{adapter}: Failed to add media query with type to style"
    end

  end

  def test_unmergable_rules_with_no_body
    html = <<END_HTML
    <html>
    <style type="text/css"> a:hover { color: red; } </style>
		<p><a>Test</a></p>
		</html>
END_HTML

    premailer = Premailer.new(html, :with_html_string => true)
    assert_nothing_raised do
      premailer.to_inline_css
    end
    assert_match /a\:hover[\s]*\{[\s]*color\:[\s]*red;[\s]*\}/i, premailer.processed_doc.at('style').inner_html
  end

  # in response to https://github.com/alexdunae/premailer/issues#issue/7
  def test_ignoring_link_pseudo_selectors
    html = <<END_HTML
    <html>
    <style type="text/css"> td a:link.top_links { color: red; } </style>
    <body>
		<td><a class="top_links">Test</a></td>
		</body>
		</html>
END_HTML

    premailer = Premailer.new(html, :with_html_string => true)
    assert_nothing_raised do
      premailer.to_inline_css
    end
    assert_match /color: red/, premailer.processed_doc.at('a').attributes['style'].to_s
  end

  # in response to https://github.com/alexdunae/premailer/issues#issue/7
  #
  # fails sometimes in JRuby, see https://github.com/alexdunae/premailer/issues/79
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
    assert_match /background: #000080/, premailer.processed_doc.search('.style5').first.attributes['style'].to_s
  end

  # in response to https://github.com/alexdunae/premailer/issues/56
  def test_inline_important
    html = <<END_HTML
    <html>
    <style type="text/css">
      p { color: red !important; }
    </style>
    <body>
      <p style='color: green !important;'>test</p></div>
    </body>
    </html>
END_HTML

    premailer = Premailer.new(html, :with_html_string => true, :adapter => :nokogiri)
    premailer.to_inline_css
    assert_equal 'color: green !important', premailer.processed_doc.search('p').first.attributes['style'].to_s
  end

  # in response to https://github.com/alexdunae/premailer/issues/28
  def test_handling_shorthand_auto_properties
    html = <<END_HTML
    <html>
    <style type="text/css">
      #page { margin: 0; margin-left: auto; margin-right: auto; }
      p { border: 1px solid black; border-right: none; }

    </style>
    <body>
      <div id='page'><p>test</p></div>
    </body>
    </html>
END_HTML

    premailer = Premailer.new(html, :with_html_string => true)
    premailer.to_inline_css

    assert_match /margin: 0 auto/, premailer.processed_doc.search('#page').first.attributes['style'].to_s
    assert_match /border-style: solid none solid solid;/, premailer.processed_doc.search('p').first.attributes['style'].to_s
  end

  def test_sorting_style_attributes
    html = <<END_HTML
    <html>
    <style type="text/css">
      #page { right: 10px; left: 5px }
    </style>
    <body>
      <div id='page'>test</div>
    </body>
    </html>
END_HTML

    premailer = Premailer.new(html, :with_html_string => true)
    premailer.to_inline_css
    assert_equal "left: 5px; right: 10px", premailer.processed_doc.search('#page').first.attributes['style'].to_s
  end

  def test_removing_scripts
    html = <<END_HTML
    <html>
    <head>
      <script>script to be removed</script>
    </head>
    <body>
      content
    </body>
    </html>
END_HTML

    [:nokogiri, :hpricot].each do |adapter|
      premailer = Premailer.new(html, :with_html_string => true, :remove_scripts => true, :adapter => adapter)
      premailer.to_inline_css
      assert_equal 0, premailer.processed_doc.search('script').length
    end

    [:nokogiri, :hpricot].each do |adapter|
      premailer = Premailer.new(html, :with_html_string => true, :remove_scripts => false, :adapter => adapter)
      premailer.to_inline_css
      assert_equal 1, premailer.processed_doc.search('script').length
    end
  end

  def test_strip_important_from_attributes
    html = <<END_HTML
    <html>
    <head>
      <style>td { background-color: #FF0000 !important; }</style>
    </head>
    <body>
      <table><tr><td>red</td></tr></table>
    </body>
    </html>
END_HTML

    [:nokogiri, :hpricot].each do |adapter|
      premailer = Premailer.new(html, :with_html_string => true, :adapter => adapter)
      assert_match 'bgcolor="#FF0000"', premailer.to_inline_css
    end
  end

  def test_scripts_with_nokogiri
    html = <<END_HTML
    <html>
    <body>
    <script type="application/ld+json">
    {
      "@context": "http://schema.org",
      "@type": "Person",
      "name": "John Doe",
      "jobTitle": "Graduate research assistant",
      "affiliation": "University of Dreams",
      "additionalName": "Johnny",
      "url": "http://www.example.com",
      "address": {
        "@type": "PostalAddress",
        "streetAddress": "1234 Peach Drive",
        "addressLocality": "Wonderland",
        "addressRegion": "Georgia"
      }
    }
    </script
    </body>
    </html>
END_HTML

    premailer = Premailer.new(html, :with_html_string => true, :remove_scripts => false, :adapter => :nokogiri)
    premailer.to_inline_css

    assert !premailer.processed_doc.css('script[type="application/ld+json"]').first.children.first.cdata?
  end
end
