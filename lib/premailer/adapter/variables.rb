module AdapterHelper
  module Variables
    def map_variables(declaration)
      while declaration.match?(/var\(\s*--([^)]+)\s*\)/)
        final_declarations = []
        declarations = declaration.split(";").map(&:strip).reject(&:empty?)
        declarations.each do |declaration|
          if match = declaration.match(/\bvar\(\s*--([^)]+)\s*\)/)
            variable = match[0]
            variable_name = match[1]
            if variable_value = css_variables[variable_name]
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
      @css_variables ||= @css_parser.find_by_selector(":root").reduce({}) do |memo, rule|
        rules = rule.split(";")
        rules.each do |rule|
          rule = rule.strip
          if match = rule.match(/--([^:]+):(.+)/)
            memo[match[1].strip] = match[2].strip
          end
        end
        memo
      end
    end
  end
end
