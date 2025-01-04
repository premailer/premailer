# frozen_string_literal: true

module AdapterHelper
  module Variables
    def map_variables(declaration)
      while declaration.match?(/\bvar\(\s*--([^)]+)\s*\)/)
        final_declarations = []
        declarations = declaration.split(";").map(&:strip).reject(&:empty?)
        declarations.each do |declaration|
          match = declaration.match(/\bvar\(\s*--([^)]+)\s*\)/)
          if match
            variable = match[0]
            variable_name = match[1]
            variable_value = css_variables[variable_name]
            unless variable_value.empty?
              final_declarations.push(declaration.gsub(variable, variable_value))
            end
          else
            final_declarations.push(declaration)
          end
        end
        declaration = final_declarations.join(";")
      end

      declaration
    end

    private

    def css_variables
      @css_variables ||= @css_parser.find_by_selector(":root").each_with_object({}) do |ruleset, memo|
        rules = ruleset.split(";")
        rules.each do |rule|
          rule = rule.strip
          match = rule.match(/--([^:]+):(.+)/)
          if match
            memo[match[1].strip] = match[2].strip
          end
        end
      end
    end
  end
end
