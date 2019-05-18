require 'parametric'
require 'delegate' # needed in older Rubies for SimpleDelegator

module Oat
  NoMethodError = Class.new(::NoMethodError)

  class DefaultPresenter < SimpleDelegator
    def initialize(item, context)
      super item
      @context = context
    end

    private
    attr_reader :context

    def item
      __getobj__
    end
  end

  class Hal
    def self.call(data)
      ents = data[:entities].each_with_object({}) do |(key, val), obj|
        obj[key] = if val.is_a?(Array)
          val.map{|v| call(v) }
        else
          call(val)
        end
      end

      out = data[:properties].dup

      if data[:links].any?
        out[:_links] = data[:links]
      end

      if ents.any?
        out.merge(
          _embedded: ents
        )
      else
        out
      end
    end
  end

  class Definition
    attr_reader :schema, :props_schema, :entities_schema, :links_schema

    def initialize
      @schema = Parametric::Schema.new
      @props_schema = Parametric::Schema.new
      @entities_schema = Parametric::Schema.new
      @links_schema = Parametric::Schema.new
      @schema.field(:properties).type(:object).schema(@props_schema)
      @schema.field(:entities).type(:object).schema(@entities_schema)
      @schema.field(:links).type(:object).schema(@links_schema)
    end

    def property(key, opts = {})
      field = props_schema.field(key)
      field.meta(from: opts.fetch(:from, key), if: opts[:if])
      field.meta(helper: opts[:helper]) if opts[:helper]
      field.type(opts[:type]) if opts[:type]
      ex = opts.fetch(:example, "example #{key}")
      field.meta(example: ex)
      field
    end

    def entities(key, opts = {}, &block)
      define_entity key, :array, opts, &block
    end

    def entity(key, opts = {}, &block)
      define_entity key, :object, opts, &block
    end

    def link(rel_name, opts = {})
      field = links_schema.field(rel_name).type(:object)
      from = opts.delete(:from)
      helper = opts.delete(:helper)
      example = opts.delete(:example)
      if !from && !helper
        raise "link '#{rel_name}' must be defined with either :from or :helper options"
      end

      field.meta(from: from) if from
      field.meta(helper: helper) if helper
      field.meta(example: example) if example
      field.meta(link_options: opts)
    end

    private

    def define_entity(key, type, opts = {}, &block)
      field = entities_schema.field(key).type(type)
      field.meta(from: opts.fetch(:from, key), if: opts[:if])
      if !opts[:with] && !block_given?
        raise "entities require a schema definition as a block or serializer class"
      elsif block_given? # sub-serialier from block
        sub = Class.new(Serializer)
        block.call sub._definition
        field.schema(sub.schema).meta(with: sub)
      else
        field.schema(opts[:with].schema).meta(with: opts[:with])
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

    def self.serialize(item, adapter: self.adapter, context: nil)
      _, pr = presenters.find{|(type, p)| type === item}
      pr = presenters[:default] unless pr
      item = pr.new(item, context) if pr
      new(item, adapter: adapter, context: context).to_h
    end

    def self._definition
      @_definition ||= Definition.new
    end

    def self.schema(&block)
      _definition.instance_eval(&block) if block_given?
      _definition.schema
    end

    def self.example(adapter: self.adapter)
      out = _definition.schema.walk(:example).output
      out[:links] = _definition.links_schema.walk do |field|
        href = field.meta_data[:example] || "https://api.com/#{field.key}"
        field.meta_data.fetch(:link_options, {}).merge(href: href)
      end.output

      adapter.call(out)
    end

    def self.presenters
      @presenters ||= {}
    end

    def self.present(presenter = nil, type: :default, &block)
      if !presenter && !block_given?
        raise "Serializer.present expects either a block or a presenter class"
      end

      if block_given?
        presenter = if parent = presenters[type] # subclass
          Class.new(parent, &block)
        else
          Class.new(DefaultPresenter, &block)
        end
      end

      presenters[type] = presenter
    end

    def self.inherited(subclass)
      presenters.each do |key, pr|
        subclass.present(pr, type: key)
      end
    end

    def initialize(item, adapter: self.class.adapter, context: nil)
      @item = item
      @adapter = adapter
      @context = context
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
    attr_reader :item, :adapter, :context

    def coerce(item, definition)
      out = {}
      out[:links] = definition.links_schema.fields.each_with_object({}) do |(key, field), obj|
        href = invoke(item, field)
        opts = field.meta_data.fetch(:link_options, {})
        obj[key] = opts.merge(href: href)
      end

      out[:properties] = definition.props_schema.fields.each_with_object({}) do |(key, field), obj|
        obj[key] = invoke(item, field) if include_field?(item, field)
      end

      out[:entities] = definition.entities_schema.fields.each_with_object({}) do |(key, field), obj|
        src = invoke(item, field)
        if field.meta_data[:type] == :array
          src = [src].flatten
          if include_field?(src, field)
            obj[key] = src.map do |sr|
              sub_output(field.meta_data[:with], sr)
            end
          end
        elsif include_field?(src, field)
          obj[key] = sub_output(field.meta_data[:with], src)
        end
      end

      out
    end

    def sub_output(serializer_klass, sub_item)
      serializer_klass.new(sub_item, adapter: adapter, context: context).resolve.output
    end

    def include_field?(item, field)
      condition = field.meta_data[:if]
      case condition
      when Symbol
        item.public_send(condition)
      else
        true
      end
    end

    def invoke(item, field)
      helper = field.meta_data[:helper]
      if helper
        if respond_to?(helper)
          return public_send(helper, item)
        else
          raise NoMethodError, "#{self.class.name} is expected to respond to ##{helper}"
        end
      end

      method_name = field.meta_data[:from]
      if item.respond_to?(method_name)
        return item.public_send(method_name)
      else
        raise NoMethodError, "#{self.class.name} expects #{item.inspect} to respond to ##{method_name}"
      end
    end
  end
end
