# https://github.com/kevinswiber/siren
module Oat
  module Adapters
    class Siren < Oat::Adapter

      def initialize(*args)
        super
        data[:links] = []
        data[:entities] = []
        data[:actions] = []
      end

      def type(*types)
        data[:class] = types
      end

      def link(rel, opts = {})
        data[:links] << {:rel => [rel]}.merge(opts)
      end

      def properties(&block)
        data[:properties].merge! yield_props(&block)
      end

      def property(key, value)
        data[:properties][key] = value
      end

      def entity(name, obj, serializer_class = nil, context_options = {}, &block)
        ent = serializer_from_block_or_class(obj, serializer_class, context_options, &block).to_hash
        data[:entities] << ent if ent
      end

      def entities(name, collection, serializer_class = nil, context_options = {}, &block)
        collection.each do |obj|
          entity name, obj, serializer_class, context_options, &block
        end
      end

      def action(name, &block)
        action = Action.new(name)
        block.call(action)

        data[:actions] << action.data
      end

      class Action
        attr_reader :data

        def initialize(name)
          @data = { :name => name, :class => [], :fields => [] }
        end

        def class(value)
          data[:class] << value
        end

        def field(name, &block)
          field = Field.new(name)
          block.call(field)

          data[:fields] << field.data
        end

        %w(href method title).each do |attribute|
          define_method(attribute) do |value|
            data[attribute.to_sym] = value
          end
        end

        class Field
          attr_reader :data

          def initialize(name)
            @data = { :name => name }
          end

          %w(type value).each do |attribute|
            define_method(attribute) do |value|
              data[attribute.to_sym] = value
            end
          end
        end
      end

    end
  end
end
