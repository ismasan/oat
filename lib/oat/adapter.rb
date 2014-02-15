require 'oat/props'
module Oat
  class Adapter

    def initialize(serializer)
      @serializer = serializer
      @data = Hash.new{|h,k| h[k] = {}}
    end

    def to_hash
      data
    end

    protected

    attr_reader :data, :serializer

    def yield_props(&block)
      props = Props.new
      serializer.instance_exec(props, &block)
      props.to_hash
    end

    def serializer_from_block_or_class(obj, serializer_class = nil, context_options = {}, &block)
      return nil if obj.nil?

      if block_given?
        serializer_class = Class.new(serializer.class)
        serializer_class.adapter self.class
        s = serializer_class.new(obj, serializer.context.merge(context_options), serializer.adapter_class, serializer.top)
        serializer.top.instance_exec(obj, s, &block)
        s.to_hash
      else
        serializer_class.new(obj, serializer.context.merge(context_options), serializer.adapter_class).to_hash
      end
    end
  end
end
