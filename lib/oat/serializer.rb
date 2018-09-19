require 'parametric'

module Oat
  NoMethodError = Class.new(::NoMethodError)

  class Hal
    def self.call(data)
      data[:properties]
    end
  end

  class Definition
    attr_reader :schema, :props_schema

    def initialize
      @schema = Parametric::Schema.new
      @props_schema = Parametric::Schema.new
      @schema.field(:properties).type(:object).schema(@props_schema)
    end

    def property(key, from: nil, type: nil, example: nil)
      field = props_schema.field(key)
      field.meta(from: from) if from
      field.type(type) if type
      ex = example ? example : "example #{key}"
      field.meta(example: ex)
      field
    end
  end

  class Serializer
    def self.adapter(adpt = nil)
      if adpt
        @adapter = adpt
      end

      @adapter || Hal
    end

    def self.serialize(item, adapter: self.adapter)
      new(item, adapter: adapter).to_h
    end

    def self._definition
      @_definition ||= Definition.new
    end

    def self.schema(&block)
      _definition.instance_eval(&block)
      _definition
    end

    def self.example(adapter: self.adapter)
      adapter.call(_definition.schema.walk(:example).output)
    end

    def initialize(item, adapter: self.class.adapter)
      @item = item
      @adapter = adapter
    end

    def to_h
      data = coerce(item, self.class._definition)
      result = self.class._definition.schema.resolve(data)
      if result.errors.any?
        raise "has errors #{result.errors.inspect}"
      end

      adapter.call(result.output)
    end

    private
    attr_reader :item, :adapter

    def coerce(item, definition)
      out = {}
      out[:properties] = definition.props_schema.fields.each_with_object({}) do |(key, field), obj|
        src = field.meta_data[:from] || key
        obj[key] = invoke(item, src)
      end

      out
    end

    def invoke(item, method_name)
      if item.respond_to?(method_name)
        item.public_send(method_name)
      else
        raise NoMethodError, "#{self.class.name} expects #{item.inspect} to respond to ##{method_name}"
      end
    end
  end
end
