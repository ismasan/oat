# frozen_string_literal: true

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

      # Sub-Entities have a required rel attribute
      # https://github.com/kevinswiber/siren#rel
      def rel(*rels)
        # rel must be an array.
        data[:rel] = Array(rels)
      end

      def type(*types)
        data[:class] = Array(types)
      end

      def title(title)
        data[:title] = title
      end

      def link(rel, opts = {})
        data[:links] << { rel: Array(rel) }.merge(opts)
      end

      def properties(&block)
        data[:properties].merge! yield_props(&block)
      end

      def property(key, value)
        data[:properties][key] = value
      end

      alias meta property

      def entity(name, obj, serializer_class = nil, context_options = {}, &block)
        ent = serializer_from_block_or_class(obj, serializer_class, context_options, &block)
        if ent
          # use the name as the sub-entities rel to the parent resource.
          ent.rel(name)
          ent_hash = ent.to_hash

          data[:entities] << ent_hash
        end
      end

      def entities(name, collection, serializer_class = nil, context_options = {}, &block)
        collection.each do |obj|
          entity name, obj, serializer_class, context_options, &block
        end
      end

      alias collection entities

      def action(name)
        action = Action.new(name)
        yield(action)

        data[:actions] << action.data
      end

      class Action
        attr_reader :data

        def initialize(name)
          @data = { name: name, class: [], fields: [] }
        end

        def klass(value)
          data[:class].concat(Array(value))
        end

        def field(name)
          field = Field.new(name)
          yield(field)

          data[:fields] << field.data
        end

        %w[categories href method title type].each do |attribute|
          define_method(attribute) do |value|
            data[attribute.to_sym] = value
          end
        end

        class Field
          attr_reader :data

          def initialize(name)
            @data = { name: name, class: [] }
          end

          def klass(value)
            data[:class].concat(Array(value))
          end

          %w[category type value title].each do |attribute|
            define_method(attribute) do |value|
              data[attribute.to_sym] = value
            end
          end
        end
      end
    end
  end
end
