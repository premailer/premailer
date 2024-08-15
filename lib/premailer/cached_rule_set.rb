# frozen_string_literal: true
class Premailer
  class CachedRuleSet < CssParser::RuleSet
    # we call this early to find errors but css-parser calls it in .merge again
    # so to prevent slowdown and bugs we refuse to run it twice on the same ruleset
    # ideally should be upstreamed into css-parser
    def expand_shorthand!
      super unless @expand_shorthand
    ensure
      @expand_shorthand = true
    end
  end
end
