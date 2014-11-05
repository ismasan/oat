require 'support/class_attribute'
module Oat
  class Serializer

    class_attribute :_adapter, :logger

    class << self
      attr_accessor :type
    end

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

    def initialize(item, context = nil, _adapter_class = nil, parent_serializer = nil)
      @item = item
      @context = context || {}
      @parent_serializer = parent_serializer
      @adapter_class = _adapter_class || self.class.adapter
      @adapter = @adapter_class.new(self)
      if self.class.type
        type(self.class.type)
      end
      @context[:_serialized_entities] ||= {}
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
        if self.class.type
          Array(item).each { |i| set_serialized(self.class.type, i.id) }
        end
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

    def set_serialized(type, id)
      @context[:_serialized_entities][type] ||= {}
      @context[:_serialized_entities][type][id] = true
    end

    def serialized?(type, id)
      h = @context[:_serialized_entities]
      h = h[type] if h
      h[id] if h
    end

  end
end
