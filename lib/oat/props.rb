module Oat
  class Props

    def initialize
      @attributes = {}
    end

    def id(value)
      @attributes[:id] = value
    end

    def _from(data)
      @attributes = data.to_hash
    end

    def method_missing(name, value)
      @attributes[name] = value
    end

    def to_hash
      @attributes
    end

  end
end
