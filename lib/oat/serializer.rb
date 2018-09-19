require 'parametric'

module Oat
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

    def property(key, from: nil, type: nil)
      field = props_schema.field(key)
      field.meta(from: from) if from
      field.type(type) if type
      field
    end
  end

  class Serializer
    def self.serialize(item)
      new(item).to_h
    end

    def self._definition
      @_definition ||= Definition.new
    end

    def self.schema(&block)
      _definition.instance_eval(&block)
      _definition
    end

    def initialize(item)
      @item = item
    end

    def to_h
      data = coerce(item, self.class._definition)
      result = self.class._definition.schema.resolve(data)
      if result.errors.any?
        raise "has errors #{result.errors.inspect}"
      end

      Hal.call(result.output)
    end

    private
    attr_reader :item

    def coerce(item, definition)
      out = {}
      out[:properties] = definition.props_schema.fields.each_with_object({}) do |(key, field), obj|
        src = field.meta_data[:from] || key
        obj[key] = item.public_send(src)
      end

      out
    end
  end
end
