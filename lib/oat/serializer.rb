require 'support/class_attribute'
module Oat
  class Serializer

    class_attribute :_adapter, :logger

    def self.schema(&block)
      @schema = block if block_given?
      @schema || Proc.new{}
    end

    def self.adapter(adapter_class = nil)
      self._adapter = adapter_class if adapter_class
      self._adapter
    end

    def self.warn(msg)
      logger ? logger.warning(msg) : Kernel.warn(msg)
    end

    attr_reader :item, :context, :adapter_class, :adapter

    def initialize(item, context = {}, _adapter_class = nil, parent_serializer = nil)
      @item, @context = item, context
      @parent_serializer = parent_serializer
      @adapter_class = _adapter_class || self.class.adapter
      @adapter = @adapter_class.new(self)
    end

    def top
      @top ||= @parent_serializer || self
    end

    def method_missing(name, *args, &block)
      if adapter.respond_to?(name)
        adapter.send(name, *args, &block)
      else
        super
      end
    end

    def individual
      if adapter.respond_to?(:individual) && adapter.method(:individual).arity == 0
        adapter.individual
      end
    end

    def type(*args)
      if adapter.respond_to?(:type) && adapter.method(:type).arity != 0
        adapter.type(*args)
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      adapter.respond_to? method_name
    end

    def to_hash
      @to_hash ||= (
        instance_eval(&self.class.schema)
        adapter.to_hash
      )
    end

    def map_properties(*args)
      args.each { |name| map_property name }
    end

    def map_property(name)
      value = item.send(name)
      property name, value
    end

  end
end
