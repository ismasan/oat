module Oat
  class Props < BasicObject

    def initialize
      @attributes = {}
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