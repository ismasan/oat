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
      def rel(rels)
        # rel must be an array.
        data[:rel] = (rels.is_a?(Array) ? rels : [rels])
      end

      # Enable collapsing of optional attributes by setting the context option
      # :collapse_optional_attributes => true
      #
      # When collapsing is enabled the Siren response will drop any empty
      # attributes from the response, since all top level entity attributes
      # are optional per the Siren spec.
      #
      # Example:
      #
      #    {
      #      "class" : [ "order" ],
      #      "properties" : {
      #        "orderNumber" :42
      #      },
      #      "entities" : [],
      #      ....
      #    }
      #
      # Would drop the empty entities:
      #
      #    {
      #      "class" : [ "order" ],
      #      "properties" : {
      #        "orderNumber" :42,
      #    .....
      #      }
      #    }
      def to_hash
        hash = data.dup

        if hash.has_key?(:properties) && serializer.context[:camelize_properties]
          hash[:properties].tap do |props|
            props.keys.each do |key|
              props[key.to_s.camelize(:lower)] = props[key]
              props.delete(key)
            end
          end
        end

        if serializer.context[:collapse_optional_attributes]
          hash.tap{|hsh| hsh.each{|k,v| hsh.delete(k) if v.empty?}}
        end

        return hash
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

      alias_method :meta, :property

      def entity(name, obj, serializer_class = nil, context_options = {}, &block)
        ent = serializer_from_block_or_class(obj, serializer_class, context_options, &block)
        if ent
          # use the name as the sub-entities rel to the parent resource.
          ent.rel(name)

          entity_hash = ent.to_hash

          # use embedded link when requested
          # https://github.com/kevinswiber/siren#embedded-link
          if serializer.context[:entity_link] || context_options[:entity_link]
            entity_hash = entity_link_hash(entity_hash)
          end

          data[:entities] << entity_hash
        end
      end

      def entities(name, collection, serializer_class = nil, context_options = {}, &block)
        collection.each do |obj|
          entity name, obj, serializer_class, context_options, &block
        end
      end

      alias_method :collection, :entities

      def entity_link_hash(entity_hash)
        entity_link_hash = {}
        # self link - TODO fix for strings, only finds if self link is a symbol
        self_link = entity_hash[:links].find{|link| link[:rel].include?(:self)}
        entity_link_hash[:href] = self_link[:href] if self_link
        entity_link_hash[:class] = entity_hash[:class] if entity_hash.has_key?(:class)
        entity_link_hash[:rel] = entity_hash[:rel] if entity_hash.has_key?(:rel)

        return entity_link_hash
      end

      private :entity_link_hash

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

        %w(href method title type).each do |attribute|
          define_method(attribute) do |value|
            data[attribute.to_sym] = value
          end
        end

        class Field
          attr_reader :data

          def initialize(name)
            @data = { :name => name }
          end

          %w(type value title).each do |attribute|
            define_method(attribute) do |value|
              data[attribute.to_sym] = value
            end
          end
        end
      end

    end
  end
end
