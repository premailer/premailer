# frozen_string_literal: true
require 'nokogiri'

class Premailer
  module Adapter
    # NokogiriFast adapter
    module NokogiriFast
      WIDTH_AND_HEIGHT = ['width', 'height'].freeze

      include AdapterHelper::RgbToHex
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

        # Create an index for nodes by tag name/id/class
        # Also precompute the map of nodes to descendants
        index, all_nodes, descendants = make_index(doc)

        # Iterate through the rules and merge them into the HTML
        @css_parser.each_selector(:all) do |selector, declaration, specificity, media_types|

          # Save un-mergable rules separately
          selector.gsub!(/:link([\s]*)+/i) { |m| $1 }

          # Convert element names to lower case
          selector.gsub!(/([\s]|^)([\w]+)/) { |m| $1.to_s + $2.to_s.downcase }

          if Premailer.is_media_query?(media_types) || selector =~ Premailer::RE_UNMERGABLE_SELECTORS
            @unmergable_rules.add_rule_set!(CssParser::RuleSet.new(selectors: selector, block: declaration), media_types) unless @options[:preserve_styles]
          else
            begin
              if Premailer::RE_RESET_SELECTORS.match?(selector)
                # this is in place to preserve the MailChimp CSS reset: http://github.com/mailchimp/Email-Blueprints/
                # however, this doesn't mean for testing pur
                @unmergable_rules.add_rule_set!(CssParser::RuleSet.new(selectors: selector, block: declaration)) unless !@options[:preserve_reset]
              end

              # Try the new index based technique. If not supported, fall back to the old brute force one.
              nodes = match_selector(index, all_nodes, descendants, selector) || doc.search(selector)
              nodes.each do |el|
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
        doc.search("script").remove if @options[:remove_scripts]

        # Read STYLE attributes and perform folding
        doc.search("*[@style]").each do |el|
          style = el.attributes['style'].to_s

          declarations = []
          style.scan(/\[SPEC\=([\d]+)\[(.[^\]\]]*)\]\]/m).each do |declaration|
            begin
              rs = CssParser::RuleSet.new(block: declaration[1].to_s, specificity: declaration[0].to_i)
              declarations << rs
            rescue ArgumentError => e
              raise e if @options[:rule_set_exceptions]
            end
          end

          # Perform style folding
          merged = CssParser.merge(declarations)
          begin
            merged.expand_shorthand!
          rescue ArgumentError => e
            raise e if @options[:rule_set_exceptions]
          end

          # Duplicate CSS attributes as HTML attributes
          if Premailer::RELATED_ATTRIBUTES.has_key?(el.name) && @options[:css_to_attributes]
            Premailer::RELATED_ATTRIBUTES[el.name].each do |css_attr, html_attr|
              if el[html_attr].nil? and not merged[css_attr].empty?
                new_val = merged[css_attr].dup

                # Remove url() function wrapper
                new_val.gsub!(/url\((['"])(.*?)\1\)/, '\2')

                # Remove !important, trailing semi-colon, and leading/trailing whitespace
                new_val.gsub!(/;$|\s*!important/, '').strip!

                # For width and height tags, remove px units
                new_val.gsub!(/(\d+)px/, '\1') if WIDTH_AND_HEIGHT.include?(html_attr)

                # For color-related tags, convert RGB to hex if specified by options
                new_val = ensure_hex(new_val) if css_attr.end_with?('color') && @options[:rgb_to_hex_attributes]

                el[html_attr] = new_val
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
          el['style'] = merged.declarations_to_s
        end

        doc = write_unmergable_css_rules(doc, @unmergable_rules) unless @options[:drop_unmergeable_css_rules]

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
        if is_xhtml?
          # we don't want to encode carriage returns
          @processed_doc.to_xhtml(:encoding => @options[:output_encoding]).gsub(/&\#(xD|13);/i, "\r")
        else
          @processed_doc.to_html(:encoding => @options[:output_encoding])
        end
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
            style_tag = doc.create_element "style", styles
            head = doc.at_css('head')
            head ||= doc.root.first_element_child.add_previous_sibling(doc.create_element "head") if doc.root && doc.root.first_element_child
            head ||= doc.add_child(doc.create_element "head")
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
          thing = URI.open(input)
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
        encoding = @options[:input_encoding] || (RUBY_PLATFORM == 'java' ? nil : 'BINARY')
        doc = if @options[:html_fragment]
          ::Nokogiri::HTML.fragment(thing, encoding)
        else
          ::Nokogiri::HTML(thing, nil, encoding) { |c| c.recover }
        end

        # Fix for removing any CDATA tags from both style and script tags inserted per
        # https://github.com/sparklemotion/nokogiri/issues/311 and
        # https://github.com/premailer/premailer/issues/199
        ['style', 'script'].each do |tag|
          doc.search(tag).children.each do |child|
            child.swap(child.text()) if child.cdata?
          end
        end

        doc
      end

      private

      # For very large documents, it is useful to trade off some memory for performance.
      # We can build an index of the nodes so we can quickly select by id/class/tagname
      # instead of search the tree again and again.
      #
      # @param page The Nokogiri HTML document to index.
      # @return [index, set_of_all_nodes, descendants] The index is a hash from key to set of nodes.
      #         The "descendants" is a hash mapping a node to the set of its descendant nodes.
      def make_index(page)
        index = {} # Contains a map of tag/class/id names to set of nodes.
        all_nodes = [] # A plain array of all nodes in the doc. The superset.
        descendants = {} # Maps node -> set of descendants

        page.traverse do |node|
          all_nodes.push(node)

          if node != page then
            index_ancestry(page, node, node.parent, descendants)
          end

          # Index the node by tag name. This is the least selective
          # of the three index types empirically.
          index[node.name] = (index[node.name] || Set.new).add(node)

          # Index the node by all class attributes it possesses.
          # Classes are modestly selective. Usually more than tag names
          # but less selective than ids.
          if node.has_attribute?("class") then
            node.get_attribute("class").split(/\s+/).each do |c|
              c = '.' + c
              index[c] = (index[c] || Set.new).add(node)
            end
          end

          # Index the node by its "id" attribute if it has one.
          # This is usually the most selective of the three.
          if node.has_attribute?("id") then
            id = '#' + node.get_attribute("id")
            index[id] = (index[id] || Set.new).add(node)
          end
        end

        # If an index key isn't there, then we should treat it as an empty set.
        # This makes the index total and we don't need to special case presence.
        # Note that the default value will never be modified. So we don't need
        # default_proc.
        index.default = Set.new
        descendants.default = Set.new

        [index, Set.new(all_nodes), descendants]
      end

      # @param doc The top level document
      # @param elem The element whose ancestry is to be captured
      # @param parent the current parent in the process of capturing. Should be set to elem.parent for starters.
      # @param descendants The running hash map of node -> set of nodes that maps descendants of a node.
      # @return The descendants argument after updating it.
      def index_ancestry(doc, elem, parent, descendants)
        if parent then
          descendants[parent] = (descendants[parent] || Set.new).add(elem)
          if doc != parent then
            index_ancestry(doc, elem, parent.parent, descendants)
          end
        end
        descendants
      end

      # @param index An index hash returned by make_index
      # @param base The base set of nodes within which the given spec is to be matched.
      # @param intersection_selector A CSS intersection selector string of the form
      #             "hello.world" or "#blue.diamond". This should not contain spaces.
      # @return Set of nodes matching the given spec that are present in the base set.
      def narrow_down_nodes(index, base, intersection_selector)
        intersection_selector.split(/(?=[.#])/).reduce(base) do |acc, sel|
          acc = index[sel].intersection(acc)
          acc
        end
      end

      # @param index An index returned by make_index
      # @param allNodes The set of all nodes in the DOM to search
      # @param selector A simple CSS tree matching selector of the form "div.container p.item span"
      # @return Set of matching nodes
      #
      # Note that fancy CSS selector syntax is not supported. Anything
      # not matching the regex /^[-a-zA-Z0-9\s_.#]*$/ should not be passed.
      # It will return nil when such a selector is passed, so you can take
      # action on the falsity of the return value.
      def match_selector(index, all_nodes, descendants, selector)
        if /[^-a-zA-Z0-9_\s.#]/.match?(selector) then
          return nil
        end

        take_children = false
        selector.split(/\s+/).reduce(all_nodes) do |base, spec|
          desc = base
          if take_children then
            desc = Set.new
            base.each do |n|
              desc.merge(descendants[n])
            end
          else
            take_children = true
          end
          narrow_down_nodes(index, desc, spec)
        end
      end
    end
  end
end
