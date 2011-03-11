# = HTTPI::Adapter
#
# Manages the adapter classes. Currently supports:
#
# * nokogiri
# * hpricot
module Adapter
		DEFAULT = :hpricot
			  
	  # Returns the adapter to use. Defaults to <tt>Adapter::</tt>.
    def self.use
      @use ||= DEFAULT
    end
		
    # Sets the +adapter+ to use. Raises an +ArgumentError+ unless the +adapter+ exists.
    def self.use=(adapter)
      validate_adapter! adapter
      @use = adapter
    end

    # Returns a memoized +Hash+ of adapters.
    def self.adapters
      @adapters ||= {
        :nokogiri => { :class => Nokogiri, :require => "nokogiri" },
        :hpricot  => { :class => Hpricot,       :require => "hpricot" },
      }
    end

    # Returns an +adapter+. Raises an +ArgumentError+ unless the +adapter+ exists.
    def self.find(adapter)
      validate_adapter! adapter
      load_adapter adapter
    end

  private

    # Raises an +ArgumentError+ unless the +adapter+ exists.
    def self.validate_adapter!(adapter)
      raise ArgumentError, "Invalid adapter: #{adapter}" unless adapters[adapter]
    end

    # Tries to load and return the given +adapter+ name and class and falls back to the +FALLBACK+ adapter.
    def self.load_adapter(adapter)
      require adapters[adapter][:require]
      [adapter, adapters[adapter][:class]]
    rescue LoadError
      puts "tried to use the #{adapter} adapter, but was unable to find the library in the LOAD_PATH."      
    end
end