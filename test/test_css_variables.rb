# frozen_string_literal: true
require __dir__ + '/helper'

class TestCssVariables < Premailer::TestCase
  def test_css_variables
    html = <<~END_HTML
      <html>
      <body>
      <style type="text/css"> :root { --red: #f00; --yellow: #ff0; --a-complicated-variableName: url("/images/logo.png"); } </style>
      <style type="text/css">
        .container { background-color: orange; }
        .container p { color: var(  --red )  ; border: 1px solid var(--yellow); background-image: linear-gradient(from top, var( --red ), var( --yellow )); }
        /* I realize this isn't the correct shorthand order for background, but I'd like to test
         * variables that are nested within the rest of the declaration */
        .brand { background: no-repeat var(--a-complicated-variableName) center center; }
      </style>
      <div class="container">
        <div class="brand"></div>
        <p>Test</p>
      </div>
      </body>
      </html>
    END_HTML

    # This should be unaffected by CSS variable parsing
    container_content = "background-color: orange"

    # These should be replaced directly
    p_color_content = "color: #f00"
    p_border_content = "border: 1px solid #ff0"
    p_gradient_content = "linear-gradient(from top, #f00, #ff0)"

    # The CSS parser will heplfully correct the shorthand order for background, but we still want to
    # ensure the variable is interpolated
    image_content = 'background: url("/images/logo.png") no-repeat center center'

    [:nokogiri, :nokogumbo, :nokogiri_fast].each do |adapter|
      premailer = Premailer.new(html, :adapter => adapter, :with_html_string => true)
      premailer.to_inline_css
      container_styles = premailer.processed_doc.at('.container')['style']
      p_styles = premailer.processed_doc.at('p')['style']
      brand_styles = premailer.processed_doc.at('.brand')['style']

      assert(container_styles.include?(container_content),
             "Expected #{container_styles.inspect} to include #{container_content.inspect} (using adapter :#{adapter})")
      assert(p_styles.include?(p_color_content),
             "Expected #{p_styles.inspect} to include #{p_color_content.inspect} (using adapter :#{adapter})")
      assert(p_styles.include?(p_border_content),
             "Expected #{p_styles.inspect} to include #{p_border_content.inspect} (using adapter :#{adapter})")
      assert(p_styles.include?(p_gradient_content),
             "Expected #{p_styles.inspect} to include #{p_gradient_content.inspect} (using adapter :#{adapter})")
      assert(brand_styles.include?(image_content),
             "Expected #{brand_styles.inspect} to include #{image_content.inspect} (using adapter :#{adapter})")
    end
  end
end
