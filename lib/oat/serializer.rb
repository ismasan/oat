require 'parametric'

module Oat
  class Hal
    def self.call(item, definition)
      out = {}
      definition.props_schema.fields.each_with_object(out) do |(key, field), obj|
        src = field.meta_data[:from] || field.key
        obj[field.key] = item.public_send(src)
      end
      out
    end
  end

  class Definition
    attr_reader :schema, :props_schema

    def initialize
      @schema = Parametric::Schema.new
      @props_schema = Parametric::Schema.new
      @schema.field(:properties).type(:object).schema(@props_schema)
    end

    def property(key, from: nil)
      field = props_schema.field(key)
      field.meta(from: from) if from
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
      Hal.call(item, self.class._definition)
    end

    private
    attr_reader :item
  end
end
