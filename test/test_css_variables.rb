# frozen_string_literal: true
require __dir__ + '/helper'

class TestCssVariables < Premailer::TestCase
  def test_css_variables
    html = <<~END_HTML
      <html>
      <body>
      <style type="text/css"> :root { --red: #f00; --yellow: #ff0; } </style>
      <style type="text/css"> p { color: var(--red); border: 1px solid var(--yellow); } </style>
      <p>Test</p>
      </body>
      </html>
    END_HTML

    color_regex = /color:\s*#f00/i
    border_regex = /border:\s*1px solid #ff0/i

    [:nokogiri, :nokogumbo, :nokogiri_fast].each do |adapter|
      premailer = Premailer.new(html, :adapter => adapter, :with_html_string => true)
      premailer.to_inline_css
      styles = premailer.processed_doc.at('p')['style']

      assert_match(color_regex, styles, "Using adapter :#{adapter}")
      assert_match(border_regex, styles, "Using adapter :#{adapter}")
    end
  end
end
