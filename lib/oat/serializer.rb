require 'support/class_attribute'

module Oat
  class Serializer

    class_attribute :_adapter, :logger, :schemas, :schema_methods

    self.schemas = []
    self.schema_methods = []

    def self.schema(&block)
      if block_given?
        schema_method_name = :"schema_block_#{self.schema_methods.count}"

        self.schemas += [block]
        self.schema_methods += [schema_method_name]

        define_method(schema_method_name, &block)
        private(schema_method_name)
      end
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
        self.class.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          private

          def #{name}(*args, &block)
            adapter.#{name}(*args, &block)
          end
        RUBY

        send(name, *args, &block)
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
        self.class.schema_methods.each do |schema_method_name|
          send(schema_method_name)
        end

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
