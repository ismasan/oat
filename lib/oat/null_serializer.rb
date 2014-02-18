require 'support/class_attribute'
module Oat
  class NullSerializer
    def method_missing(*args)
      self
    end

    def to_hash
      nil
    end
  end
end
