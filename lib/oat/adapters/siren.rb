# https://github.com/kevinswiber/siren
module Oat
  module Adapters
    class Siren < Oat::Adapter

      def initialize(*args)
        super
        data[:links] = []
        data[:entities] = []
      end

      def type(*types)
        data[:class] = types
      end

      def link(rel, opts = {})
        data[:links] << {rel: [rel]}.merge(opts)
      end

      def properties(&block)
        data[:properties].merge! yield_props(&block)
      end

      def property(key, value)
        data[:properties][key] = value
      end

      def entity(name, obj, serializer_class = nil, &block)
        ent = obj ? serializer_from_block_or_class(obj, serializer_class, &block) : nil
        data[:entities] << ent
      end

      def entities(name, collection, serializer_class = nil, &block)
        collection.each do |obj|
          entity name, obj, serializer_class, &block
        end
      end

    end
  end
end
