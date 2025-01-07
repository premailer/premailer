# frozen_string_literal: true

module AdapterHelper
  module Variables
    CSS_VARIABLE_REGEX = /\bvar\(\s*--([^\s)]+)\s*\)/
    # Takes a CSS declaration string and replaces any `var(--my-variable-name)` references with
    # variables loaded from document's styles
    def map_variables(styles)
      return styles if css_variables.empty?
      return styles unless styles.match?(CSS_VARIABLE_REGEX)

      final_declarations = []
      declarations = styles.split(";").map(&:strip).reject(&:empty?)
      declarations.each do |declaration|
        while match = declaration.match(CSS_VARIABLE_REGEX)
          variable = match[0]
          variable_name = match[1].downcase
          variable_value = css_variables[variable_name]
          declaration = declaration.gsub(variable, variable_value)
        end

        final_declarations.push(declaration)
      end

      final_declarations.join(";")
    end

    private

    def css_variables
      @css_variables ||= @css_parser.find_by_selector(":root").each_with_object({}) do |ruleset, memo|
        rules = ruleset.split(";")
        rules.each do |rule|
          rule.strip!
          match = rule.match(/--([^:\s]+):(.+)/)
          if match
            memo[match[1].strip] = match[2].strip
          end
        end
      end
    end
  end
end
