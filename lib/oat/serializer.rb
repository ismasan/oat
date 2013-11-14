require 'active_support/core_ext/class/attribute'
module Oat
  class Serializer

    class_attribute :_adapter

    def self.schema(&block)
      @schema = block if block_given?
      @schema || Proc.new{}
    end

    def self.adapter(adapter_class = nil)
      self._adapter = adapter_class if adapter_class
      self._adapter
    end

    attr_reader :item, :context, :adapter

    def initialize(item, context = nil, parent_serializer = nil)
      @item, @context = item, context
      @parent_serializer = parent_serializer
      @adapter = self.class.adapter.new(self)
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

    def to_hash
      @to_hash ||= (
        self.instance_eval &self.class.schema
        adapter.to_hash
      )
    end

  end
end