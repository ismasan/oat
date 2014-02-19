module Oat
  class Data < Hash
    def to_hash
      self.reduce({}) do |memo,(k,v)|
        if v.is_a?(Array)
          memo[k] = v.map{ |arr_val| arr_val.respond_to?(:to_hash) ? arr_val.to_hash : arr_val }
        else
          memo[k] = v.respond_to?(:to_hash) ? v.to_hash : v
        end
        memo
      end
    end
  end
end
