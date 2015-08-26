require 'nokogiri'

class Premailer
  module Adapter
    # Nokogiri adapter
    module Nokogiri

      # Merge CSS into the HTML document.
      #
      # @return [String] an HTML.
      def to_inline_css
        doc = @processed_doc
        @unmergable_rules = CssParser::Parser.new

        # Give all styles already in style attributes a specificity of 1000
        # per http://www.w3.org/TR/CSS21/cascade.html#specificity
        doc.search("*[@style]").each do |el|
          el['style'] = '[SPEC=1000[' + el.attributes['style'] + ']]'
        end

        # Iterate through the rules and merge them into the HTML
        @css_parser.each_selector(:all) do |selector, declaration, specificity, media_types|
          # Save un-mergable rules separately
          selector.gsub!(/:link([\s]*)+/i) { |m| $1 }

          # Convert element names to lower case
          selector.gsub!(/([\s]|^)([\w]+)/) { |m| $1.to_s + $2.to_s.downcase }

          if Premailer.is_media_query?(media_types) || selector =~ Premailer::RE_UNMERGABLE_SELECTORS
            @unmergable_rules.add_rule_set!(CssParser::RuleSet.new(selector, declaration), media_types) unless @options[:preserve_styles]
          else
            begin
              if selector =~ Premailer::RE_RESET_SELECTORS
                # this is in place to preserve the MailChimp CSS reset: http://github.com/mailchimp/Email-Blueprints/
                # however, this doesn't mean for testing pur
                @unmergable_rules.add_rule_set!(CssParser::RuleSet.new(selector, declaration)) unless !@options[:preserve_reset]
              end

              # Change single ID CSS selectors into xpath so that we can match more
              # than one element.  Added to work around dodgy generated code.
              selector.gsub!(/\A\#([\w_\-]+)\Z/, '*[@id=\1]')

              doc.search(selector).each do |el|
                if el.elem? and (el.name != 'head' and el.parent.name != 'head')
                  # Add a style attribute or append to the existing one
                  block = "[SPEC=#{specificity}[#{declaration}]]"
                  el['style'] = (el.attributes['style'].to_s ||= '') + ' ' + block
                end
              end
            rescue ::Nokogiri::SyntaxError, RuntimeError, ArgumentError
              $stderr.puts "CSS syntax error with selector: #{selector}" if @options[:verbose]
              next
            end
          end
        end

        # Remove script tags
        if @options[:remove_scripts]
          doc.search("script").remove
        end

        # Read STYLE attributes and perform folding
        doc.search("*[@style]").each do |el|
          style = el.attributes['style'].to_s

          declarations = []
          style.scan(/\[SPEC\=([\d]+)\[(.[^\]\]]*)\]\]/).each do |declaration|
            rs = CssParser::RuleSet.new(nil, declaration[1].to_s, declaration[0].to_i)
            declarations << rs
          end

          # Perform style folding
          merged = CssParser.merge(declarations)
          merged.expand_shorthand!

          # Duplicate CSS attributes as HTML attributes
          if Premailer::RELATED_ATTRIBUTES.has_key?(el.name)
            Premailer::RELATED_ATTRIBUTES[el.name].each do |css_att, html_att|
              el[html_att] = merged[css_att].gsub(/url\(['|"](.*)['|"]\)/, '\1').gsub(/;$|\s*!important/, '').strip if el[html_att].nil? and not merged[css_att].empty?
            end
          end

          # Collapse multiple rules into one as much as possible.
          merged.create_shorthand!

          # write the inline STYLE attribute
          attributes = Premailer.escape_string(merged.declarations_to_s).split(';').map(&:strip)
          attributes = attributes.map { |attr| [attr.split(':').first, attr] }.sort_by { |pair| pair.first }.map { |pair| pair[1] }
          el['style'] = attributes.join('; ')
        end

        doc = write_unmergable_css_rules(doc, @unmergable_rules)

        if @options[:remove_classes] or @options[:remove_comments]
          doc.traverse do |el|
            if el.comment? and @options[:remove_comments]
              el.remove
            elsif el.element?
              el.remove_attribute('class') if @options[:remove_classes]
            end
          end
        end

        if @options[:remove_ids]
          # find all anchor's targets and hash them
          targets = []
          doc.search("a[@href^='#']").each do |el|
            target = el.get_attribute('href')[1..-1]
            targets << target
            el.set_attribute('href', "#" + Digest::MD5.hexdigest(target))
          end
          # hash ids that are links target, delete others
          doc.search("*[@id]").each do |el|
            id = el.get_attribute('id')
            if targets.include?(id)
              el.set_attribute('id', Digest::MD5.hexdigest(id))
            else
              el.remove_attribute('id')
            end
          end
        end

        if @options[:reset_contenteditable]
          doc.search('*[@contenteditable]').each do |el|
            el.remove_attribute('contenteditable')
          end
        end

        @processed_doc = doc
        if is_xhtml?
          # we don't want to encode carriage returns
          @processed_doc.to_xhtml(:encoding => @options[:output_encoding]).gsub(/&\#(xD|13);/i, "\r")
        else
          @processed_doc.to_html(:encoding => @options[:output_encoding])
        end
      end

      # Create a <tt>style</tt> element with un-mergable rules (e.g. <tt>:hover</tt>)
      # and write it into the <tt>body</tt>.
      #
      # <tt>doc</tt> is an Nokogiri document and <tt>unmergable_css_rules</tt> is a Css::RuleSet.
      #
      # @return [::Nokogiri::XML] a document.
      def write_unmergable_css_rules(doc, unmergable_rules) # :nodoc:
        styles = unmergable_rules.to_s

        unless styles.empty?
          style_tag = "<style type=\"text/css\">\n#{styles}</style>"
          unless (body = doc.search('body')).empty?
            if doc.at_css('body').children && !doc.at_css('body').children.empty?
              doc.at_css('body').children.before(::Nokogiri::XML.fragment(style_tag))
            else
              doc.at_css('body').add_child(::Nokogiri::XML.fragment(style_tag))
            end
          else
            doc.inner_html = style_tag += doc.inner_html
          end
        end
        doc
      end


      # Converts the HTML document to a format suitable for plain-text e-mail.
      #
      # If present, uses the <body> element as its base; otherwise uses the whole document.
      #
      # @return [String] a plain text.
      def to_plain_text
        html_src = ''
        begin
          html_src = @doc.at("body").inner_html
        rescue;
        end

        html_src = @doc.to_html unless html_src and not html_src.empty?
        convert_to_text(html_src, @options[:line_length], @html_encoding)
      end

      # Gets the original HTML as a string.
      # @return [String] HTML.
      def to_s
        if is_xhtml?
          @doc.to_xhtml(:encoding => nil)
        else
          @doc.to_html(:encoding => nil)
        end
      end

      # Load the HTML file and convert it into an Nokogiri document.
      #
      # @return [::Nokogiri::XML] a document.
      def load_html(input) # :nodoc:
        thing = nil

        # TODO: duplicate options
        if @options[:with_html_string] or @options[:inline] or input.respond_to?(:read)
          thing = input
        elsif @is_local_file
          @base_dir = File.dirname(input)
          thing = File.open(input, 'r')
        else
          thing = open(input)
        end

        if thing.respond_to?(:read)
          thing = thing.read
        end

        return nil unless thing
        doc = nil

        # Handle HTML entities
        if @options[:replace_html_entities] == true and thing.is_a?(String)
          HTML_ENTITIES.map do |entity, replacement|
            thing.gsub! entity, replacement
          end
        end
        # Default encoding is ASCII-8BIT (binary) per http://groups.google.com/group/nokogiri-talk/msg/0b81ef0dc180dc74
        # However, we really don't want to hardcode this. ASCII-8BIT should be the default, but not the only option.
        if thing.is_a?(String) and RUBY_VERSION =~ /1.9/
          thing = thing.force_encoding(@options[:input_encoding]).encode!
          doc = ::Nokogiri::HTML(thing, nil, @options[:input_encoding]) { |c| c.recover }
        else
          default_encoding = RUBY_PLATFORM == 'java' ? nil : 'BINARY'
          doc = ::Nokogiri::HTML(thing, nil, @options[:input_encoding] || default_encoding) { |c| c.recover }
        end

        # Fix for removing any CDATA tags from both style and script tags inserted per
        # https://github.com/sparklemotion/nokogiri/issues/311 and
        # https://github.com/premailer/premailer/issues/199
        %w(style script).each do |tag|
          doc.search(tag).children.each do |child|
            child.swap(child.text()) if child.cdata?
          end
        end

        doc
      end

    end
  end
end
