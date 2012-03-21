

class Premailer
  # Manages the adapter classes. Currently supports:
  #
  # * nokogiri
  # * hpricot
  module Adapter

    autoload :Hpricot, 'premailer/adapter/hpricot'
    autoload :Nokogiri, 'premailer/adapter/nokogiri'

    # adapter to required file mapping.
    REQUIREMENT_MAP = [
      ["hpricot",  :hpricot],
      ["nokogiri", :nokogiri],
    ]

    # Returns the adapter to use.
    def self.use
      return @use if @use
      self.use = self.default
      @use
    end

    # The default adapter based on what you currently have loaded and
    # installed. First checks to see if any adapters are already loaded,
    # then checks to see which are installed if none are loaded.
    # @raise [RuntimeError] unless suitable adapter found.
    def self.default
      return :hpricot  if defined?(::Hpricot)
      return :nokogiri if defined?(::Nokogiri)

      REQUIREMENT_MAP.each do |(library, adapter)|
        begin
          require library
          return adapter
        rescue LoadError
          next
        end
      end

      raise RuntimeError.new("No suitable adapter for Premailer was found, please install hpricot or nokogiri")
    end

    # Sets the adapter to use.
    # @raise [ArgumentError] unless the adapter exists.
    def self.use=(new_adapter)
      @use = find(new_adapter)
    end

    # Returns an adapter.
    # @raise [ArgumentError] unless the adapter exists.
    def self.find(adapter)
      return adapter if adapter.is_a?(Module)

      Premailer::Adapter.const_get("#{adapter.to_s.split('_').map{|s| s.capitalize}.join('')}")
    rescue NameError
      raise ArgumentError, "Invalid adapter: #{adapter}"
    end

  end
end
