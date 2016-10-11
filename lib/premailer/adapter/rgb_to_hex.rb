# RGB helper for adapters, currently only nokogiri supported

module AdapterHelper
  module RgbToHex
    def to_hex(str)
      str.to_i.to_s(16).rjust(2, '0').upcase
    end

    def is_rgb?(color)
      pattern = %r{
      rgb
      \(          # literal open
      (\d{1,3})   # capture 1-3 digits
      \s*,\s*     # comma, with optional whitespace
      (\d{1,3})   # capture 1-3 digits
      \s*,\s*     # comma, with optional whitespace
      (\d{1,3})   # capture 1-3 digits
      \)          # literal close
      }x

      pattern.match(color)
    end

    def ensure_hex(color)
      match_data = is_rgb?(color)
      if match_data
        "#{to_hex(match_data[1])}#{to_hex(match_data[2])}#{to_hex(match_data[3])}"
      end
    end
  end
end