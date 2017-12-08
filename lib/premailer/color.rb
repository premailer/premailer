class Premailer
  class Color

    DEFAULT_BACKGROUND_COLOR = "rgb(255,255,255)"

    RGB_PATTERN = %r{
    rgba?
    \(\s*         # literal open, with optional whitespace
    (?<r>\d{1,3}) # capture 1-3 digits for red
    \s*,\s*       # comma, with optional whitespace
    (?<g>\d{1,3}) # capture 1-3 digits for green
    \s*,\s*       # comma, with optional whitespace
    (?<b>\d{1,3}) # capture 1-3 digits for blue
    \s*,?\s*      # comma, with optional whitespace
    (?<a>         # start optional alpha channel
      1|          # digit 1 on itself, or...
      1\.0*?|     # 1.0, or...
      0|          # digit 0 on itself, or ...
      0?\.\d*?    # 0 with dot and opacity digits
    )?            # close alpha channel
    \s*\)         # literal close, with optional whitespace
    }x

    HEX_PATTERN_6 = /\A#?(?<r>\h{2})(?<g>\h{2})(?<b>\h{2})\z/
    HEX_PATTERN_3 = /\A#?(?<r>\h{1})(?<g>\h{1})(?<b>\h{1})\z/

    attr_reader :r, :g, :b, :a

    def self.default
      Color.new(255,255,255)
    end

    def self.parse(string)
      return string if Color === string || TransparentColor === string || NamedColor === string
      case
      when match_data = HEX_PATTERN_6.match(string)
        color_array = match_data.captures.map{|m| m.hex }
        new(*color_array)
      when match_data = RGB_PATTERN.match(string)
        string_color_array = match_data.captures.compact
        if string_color_array.size == 3
          color_array = string_color_array
        else
          color_array = string_color_array[0..2].map(&:to_i)
          color_array << string_color_array[3].to_f
        end
        new(*color_array)
      when match_data = HEX_PATTERN_3.match(string)
        color_array = match_data.captures.map{ |m| (m * 2).hex }
        new(*color_array)
      when string == "transparent"
        TransparentColor.new(string)
      else
        NamedColor.new(string)
      end
    end

    def initialize(r,g,b,a=1.0)
      @r = r.to_i
      @g = g.to_i
      @b = b.to_i
      @a = a.to_f
    end

    def to_s
      hex = [@r,@g,@b].map{ |n| n.to_s(16).rjust(2, '0').upcase }
      "##{hex.join}"
    end

    def inspect
      "Color(#{to_s})"
    end

    def opaque?
      @a == 1.0
    end

    def blend(background)
      return self if opaque?
      background = DEFAULT_BACKGROUND_COLOR if NamedColor === background

      background = Color.parse(background)
      background.opaque? or raise ArgumentError, "Expected opaque background color"

      alpha = (1 - @a)
      red   = (alpha * background.r) + (@a * @r)
      green = (alpha * background.g) + (@a * @g)
      blue  = (alpha * background.b) + (@a * @b)

      Color.new(red.round,green.round,blue.round)
    end
  end

  class NamedColor
    def initialize(string)
      @name = string
    end

    def opaque?
      true
    end

    def blend(background)
      return self
    end

    def inspect
      "NamedColor(#{to_s})"
    end

    def to_s
      @name
    end
  end

  class TransparentColor
    def initialize(string)
      @name = string
    end

    def opaque?
      false
    end

    def blend(background)
      return background
    end

    def inspect
      "TransparentColor(#{to_s})"
    end

    def to_s
      @name
    end
  end
end
