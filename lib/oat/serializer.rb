require 'parametric'

module Oat
  NoMethodError = Class.new(::NoMethodError)

  class Hal
    def self.call(data)
      ents = data[:entities].each_with_object({}) do |(key, val), obj|
        obj[key] = if val.is_a?(Array)
          val.map{|v| call(v) }
        else
          call(val)
        end
      end

      data[:properties].merge(
        _embedded: ents
      )
    end
  end

  class Definition
    attr_reader :schema, :props_schema, :entities_schema

    def initialize
      @schema = Parametric::Schema.new
      @props_schema = Parametric::Schema.new
      @entities_schema = Parametric::Schema.new
      @schema.field(:properties).type(:object).schema(@props_schema)
      @schema.field(:entities).type(:object).schema(@entities_schema)
    end

    def property(key, from: nil, type: nil, example: nil)
      field = props_schema.field(key)
      field.meta(from: from || key)
      field.type(type) if type
      ex = example ? example : "example #{key}"
      field.meta(example: ex)
      field
    end

    def entities(key, from: nil, with: nil, &block)
      field = entities_schema.field(key).type(:array)
      field.meta(from: from || key)
      if !with && !block_given?
        raise "entities require a schema definition as a block or serializer class"
      elsif block_given? # sub-serialier from block
        sub = Class.new(Serializer)
        block.call sub._definition
        field.schema(sub.schema).meta(with: sub)
      else
        field.schema(with.schema).meta(with: with)
      end

      field
    end

    def entity(key, from: nil, with: nil, &block)
      field = entities_schema.field(key).type(:object)
      field.meta(from: from || key)
      if !with && !block_given?
        raise "entities require a schema definition as a block or serializer class"
      elsif block_given? # sub-serialier from block
        sub = Class.new(Serializer)
        block.call sub._definition
        field.schema(sub.schema).meta(with: sub)
      else
        field.schema(with.schema).meta(with: with)
      end

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
      _definition.instance_eval(&block) if block_given?
      _definition.schema
    end

    def self.example(adapter: self.adapter)
      adapter.call(_definition.schema.walk(:example).output)
    end

    def initialize(item, adapter: self.class.adapter)
      @item = item
      @adapter = adapter
    end

    def to_h
      result = resolve
      if result.errors.any?
        raise "has errors #{result.errors.inspect}"
      end

      adapter.call(result.output)
    end

    protected

    def resolve
      data = coerce(item, self.class._definition)
      self.class._definition.schema.resolve(data)
    end

    private
    attr_reader :item, :adapter

    def coerce(item, definition)
      out = {}
      out[:properties] = definition.props_schema.fields.each_with_object({}) do |(key, field), obj|
        obj[key] = invoke(item, field.meta_data[:from])
      end

      out[:entities] = definition.entities_schema.fields.each_with_object({}) do |(key, field), obj|
        src = invoke(item, field.meta_data[:from])
        sub_out = if field.meta_data[:type] == :array
          [src].flatten.map do |sr|
            field.meta_data[:with].new(sr, adapter: adapter).resolve.output
          end
        else
          field.meta_data[:with].new(src, adapter: adapter).resolve.output
        end

        obj[key] = sub_out
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
