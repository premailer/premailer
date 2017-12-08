# RGB helper for adapters, currently only nokogiri supported
require 'premailer/color'

class Premailer
  module RgbToHex

    def ensure_hex(color, el=nil)
      parsed = Color.parse(color)
      if parsed.opaque?
        return parsed
      else
        blend_with_ancestors(parsed, el)
      end
    end

    def blend_with_ancestors(color, element)
      ancestors = element.respond_to?(:ancestors) ? element.ancestors : []
      return color.blend(Color.default) if ancestors.empty?

      bgcolors = ancestors.map { |a| a["bgcolor"] }.compact
      chain = [color].concat(bgcolors).map{ |c| Color.parse(c) }

      chain.reverse.reduce(Color.default) { |background, layer| layer.blend(background) }
    end
  end
end
