# frozen_string_literal: true
require __dir__ + '/helper'

class TestCssVariables < Premailer::TestCase
  [:nokogiri, :nokogumbo, :nokogiri_fast].each do |adapter|
    class_eval <<~RUBY, __FILE__, __LINE__ + 1
      # Test that CSS variables are inlined correctly with the #{adapter} adapter
      def test_css_variables_in_#{adapter}
        html = <<~END_HTML
          <html>
          <body>
          <style type="text/css"> :root { --red: #f00; --yellow: #ff0; } </style>
          <style type="text/css"> p { color: var(--red); border: 1px solid var(--yellow); } </style>
          <p>Test</p>
          </body>
          </html>
        END_HTML

        premailer = Premailer.new(html, :adapter => :#{adapter}, :with_html_string => true)
        premailer.to_inline_css

        assert_match /color:\s*#f00/i, premailer.processed_doc.at('p')['style']
        assert_match /border:\s*1px solid #ff0/i, premailer.processed_doc.at('p')['style']
      end
    RUBY
  end
end
