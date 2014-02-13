# http://stateless.co/hal_specification.html
module Oat
  module Adapters
    class HAL < Oat::Adapter
      def link(rel, opts = {})
        data[:_links][rel] = opts if opts[:href]
      end

      def properties(&block)
        data.merge! yield_props(&block)
      end

      def property(key, value)
        data[key] = value
      end

      def entity(name, obj, serializer_class = nil, &block)
        entity_serializer = serializer_from_block_or_class(obj, serializer_class, &block)
        data[:_embedded][name] = entity_serializer ? entity_serializer.to_hash : nil
      end

      def entities(name, collection, serializer_class = nil, &block)
        data[:_embedded][name] = collection.map do |obj|
          entity_serializer = serializer_from_block_or_class(obj, serializer_class, &block)
          entity_serializer ? entity_serializer.to_hash : nil
        end
      end

    end
  end
end
