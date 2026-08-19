# frozen_string_literal: true
require 'nokogiri'

class Premailer
  module Adapter
    # Nokogiri adapter
    module Nokogiri
      WIDTH_AND_HIGHT = ['width', 'height'].freeze

      include AdapterHelper::RgbToHex
      # Merge CSS into the HTML document.
      #
      # @return [String] an HTML.
      def to_inline_css
        doc = @processed_doc
        @unmergable_rules = CssParser::Parser.new

        # Accumulate matched rule sets per node in memory instead of
        # round-tripping them through style attributes as [SPEC=n[...]]
        # string markers (which costs two libxml2 attribute round-trips per
        # element plus a regex re-scan, and dominates allocation churn).
        rules_by_node = {}

        # Give all styles already in style attributes a specificity of 1000
        # per http://www.w3.org/TR/CSS21/cascade.html#specificity
        # Identical style strings (repeated components) share one rule set so
        # the fold cache below can hit on them.
        rule_set_cache = {}
        doc.search("*[@style]").each do |el|
          style = el.attributes['style'].to_s
          rs = rule_set_cache.fetch(style) { rule_set_cache[style] = build_rule_set(style, 1000) }
          rules_by_node[el] = rs ? [rs] : []
        end
        # Iterate through the rules and merge them into the HTML
        @css_parser.each_selector(:all) do |selector, declaration, specificity, media_types|
          # Save un-mergable rules separately
          selector.gsub!(/:link([\s]*)+/i) { |_m| $1 }

          # Convert element names to lower case
          selector.gsub!(/([\s]|^)([\w]+)/) { |_m| $1.to_s + $2.to_s.downcase }

          if Premailer.media_query?(media_types) || selector =~ Premailer::RE_UNMERGABLE_SELECTORS
            @unmergable_rules.add_rule_set!(CssParser::RuleSet.new(selectors: selector, block: declaration), media_types) unless @options[:preserve_styles]
          else
            begin
              if Premailer::RE_RESET_SELECTORS.match?(selector) && !!@options[:preserve_reset]
                # this is in place to preserve the MailChimp CSS reset: http://github.com/mailchimp/Email-Blueprints/
                # however, this doesn't mean for testing pur
                @unmergable_rules.add_rule_set!(CssParser::RuleSet.new(selectors: selector, block: declaration))
              end

              # Change single ID CSS selectors into xpath so that we can match more
              # than one element.  Added to work around dodgy generated code.
              selector.gsub!(/\A\#([\w_\-]+)\Z/, '*[@id=\1]')

              rule_set = nil
              rule_set_missing = false
              doc.search(selector).each do |el|
                if el.elem? && ((el.name != 'head') && (el.parent.name != 'head'))
                  # Enroll the element even when the rule below fails to build:
                  # the marker implementation wrote the style attribute before
                  # parsing, so matched elements end up with style="" when
                  # their only rule is invalid and exceptions are disabled.
                  rules = (rules_by_node[el] ||= [])
                  next if rule_set_missing

                  # One shared rule set per CSS rule; merge never mutates inputs
                  # (CachedRuleSet#expand_shorthand! is idempotent by design).
                  rule_set ||= build_rule_set(declaration, specificity)
                  if rule_set.nil?
                    rule_set_missing = true
                    next
                  end
                  rules << rule_set
                end
              end
            rescue ::Nokogiri::SyntaxError, RuntimeError, ArgumentError
              warn "CSS syntax error with selector: #{selector}" if @options[:verbose]
              next
            end
          end
        end

        # Remove script tags
        doc.search("script").remove if @options[:remove_scripts]

        # Perform style folding. Elements sharing the same matched rule sets
        # (ubiquitous in table-based email markup) fold to the same result, so
        # the merge/expand/collapse/serialize pipeline runs once per unique
        # (element name, rule list) pair instead of once per element.
        fold_cache = {}
        rules_by_node.each do |el, declarations|
          related = Premailer::RELATED_ATTRIBUTES.key?(el.name) && @options[:css_to_attributes]
          # Rule sets are interned above, so default identity hashing makes
          # them usable directly as cache key elements.
          cache_key = [related ? el.name : nil, *declarations]

          folded = fold_cache[cache_key] ||= fold_declarations(declarations, related ? el.name : nil)
          style, attributes = folded

          # Write the inline STYLE attribute first so the attribute order for
          # elements that had no style attribute matches the marker-based
          # implementation (style attr was created during selector matching).
          el['style'] = style

          attributes&.each do |html_attr, value|
            el[html_attr] = value if el[html_attr].nil?
          end
        end

        doc = write_unmergable_css_rules(doc, @unmergable_rules) unless @options[:drop_unmergeable_css_rules]

        if @options[:remove_classes] || @options[:remove_comments]
          doc.traverse do |el|
            if el.comment? && @options[:remove_comments]
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
            target = el.get_attribute('href')[1..]
            targets << target
            el.set_attribute('href', "#" + Digest::SHA256.hexdigest(target))
          end
          # hash ids that are links target, delete others
          doc.search("*[@id]").each do |el|
            id = el.get_attribute('id')
            if targets.include?(id)
              el.set_attribute('id', Digest::SHA256.hexdigest(id))
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
        if xhtml?
          # we don't want to encode carriage returns
          @processed_doc.to_xhtml(:encoding => @options[:output_encoding]).gsub(/&\#(xD|13);/i, "\r")
        else
          @processed_doc.to_html(:encoding => @options[:output_encoding])
        end
      end

      # Merge a list of rule sets into a final style string plus the HTML
      # attribute duplications (bgcolor/align/...) for RELATED_ATTRIBUTES
      # elements. Element-independent: the per-element "attribute already
      # set" guard stays with the caller.
      def fold_declarations(declarations, related_el_name) # :nodoc:
        merged = CssParser.merge(declarations)
        if merged.equal?(declarations[0])
          # CssParser.merge returns its input untouched when given a single
          # rule set; copy it before the destructive fold pipeline below so
          # rule sets shared across elements are not corrupted.
          merged = CssParser::RuleSet.new(block: merged.declarations_to_s, specificity: merged.specificity)
        end
        begin
          merged.expand_shorthand!
        rescue ArgumentError => e
          raise e if @options[:rule_set_exceptions]
        end

        attributes = nil
        # Duplicate CSS attributes as HTML attributes
        if related_el_name
          Premailer::RELATED_ATTRIBUTES[related_el_name].each do |css_attr, html_attr|
            unless merged[css_attr].empty?
              new_val = merged[css_attr].dup

              # Remove url() function wrapper
              new_val.gsub!(/url\((['"])(.*?)\1\)/, '\2')

              # Remove !important, trailing semi-colon, and leading/trailing whitespace
              new_val.gsub!(/;$|\s*!important/, '').strip!

              # For width and height tags, remove px units
              new_val.gsub!(/(\d+)px/, '\1') if WIDTH_AND_HIGHT.include?(html_attr)

              # For color-related tags, convert RGB to hex if specified by options
              new_val = ensure_hex(new_val) if css_attr.end_with?('color') && @options[:rgb_to_hex_attributes]

              (attributes ||= []) << [html_attr, new_val]
            end

            unless @options[:preserve_style_attribute]
              merged.instance_variable_get(:@declarations).tap do |declarations|
                declarations.delete(css_attr)
              end
            end
          end
        end

        # Collapse multiple rules into one as much as possible.
        merged.create_shorthand! if @options[:create_shorthands]

        # write the inline STYLE attribute
        [merged.declarations_to_s, attributes]
      end

      # Build an expanded rule set for folding. Returns nil (and optionally
      # swallows the error, mirroring the old fold-time rescue) on bad CSS.
      def build_rule_set(block, specificity) # :nodoc:
        rs = Premailer::CachedRuleSet.new(block: block, specificity: specificity)
        rs.expand_shorthand!
        rs
      rescue ArgumentError => e
        raise e if @options[:rule_set_exceptions]
        nil
      end

      # Create a <tt>style</tt> element with un-mergable rules (e.g. <tt>:hover</tt>)
      # and write it into the <tt>head</tt>.
      #
      # <tt>doc</tt> is an Nokogiri document and <tt>unmergable_css_rules</tt> is a Css::RuleSet.
      #
      # @return [::Nokogiri::XML] a document.
      def write_unmergable_css_rules(doc, unmergable_rules) # :nodoc:
        styles = unmergable_rules.to_s
        unless styles.empty?
          if @options[:html_fragment]
            style_tag = ::Nokogiri::XML::Node.new("style", doc)
            style_tag.content = styles
            doc.add_child(style_tag)
          else
            style_tag = doc.create_element "style", styles.to_s
            head = doc.at_css('head')
            head ||=  doc.root.first_element_child.add_previous_sibling(doc.create_element("head")) if doc.root&.first_element_child
            head ||=  doc.add_child(doc.create_element("head"))
            head << style_tag
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
        rescue StandardError
        end

        html_src = @doc.to_html unless html_src && !html_src.empty?
        convert_to_text(html_src, @options[:line_length], @html_encoding)
      end

      # Gets the original HTML as a string.
      # @return [String] HTML.
      def to_s
        if xhtml?
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
        if @options[:with_html_string] || @options[:inline] || input.respond_to?(:read)
          thing = input
        elsif @is_local_file
          @base_dir = File.dirname(input)
          thing = File.open(input, 'r')
        else
          thing = URI.parse(input).open
        end

        if thing.respond_to?(:read)
          thing = thing.read
        end

        return nil unless thing
        doc = nil

        # Handle HTML entities
        if (@options[:replace_html_entities] == true) && thing.is_a?(String)
          thing = +thing
          HTML_ENTITIES.map do |entity, replacement|
            thing.gsub! entity, replacement
          end
        end
        encoding = @options[:input_encoding] || (RUBY_PLATFORM == 'java' ? nil : 'BINARY')
        doc = if @options[:html_fragment]
          ::Nokogiri::HTML.fragment(thing, encoding)
        else
          ::Nokogiri::HTML(thing, nil, encoding, &:recover)
        end

        # Fix for removing any CDATA tags from both style and script tags inserted per
        # https://github.com/sparklemotion/nokogiri/issues/311 and
        # https://github.com/premailer/premailer/issues/199
        ['style', 'script'].each do |tag|
          doc.search(tag).children.each do |child|
            child.swap(child.text) if child.cdata?
          end
        end

        doc
      end
    end
  end
end
