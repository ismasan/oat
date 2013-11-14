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
        data[:entities] << serializer_from_block_or_class(obj, serializer_class, &block)
      end

      def entities(name, collection, serializer_class = nil, &block)
        data[:entities] += collection.map do |obj|
          serializer_from_block_or_class(obj, serializer_class, &block)
        end
      end

    end
  end
end