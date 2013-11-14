module Oat
  module Adapters
    class HAL < Oat::Adapter
      def link(rel, opts = {})
        data[:_links][rel] = opts
      end

      def properties(&block)
        data.merge! yield_props(&block)
      end

      def property(key, value)
        data[key] = value
      end

      def entity(name, obj, serializer_class = nil, &block)
        data[:_embedded][name] = serializer_from_block_or_class(obj, serializer_class, &block)
      end

      def entities(name, collection, serializer_class = nil, &block)
        data[:_embedded][name] = collection.map do |obj|
          serializer_from_block_or_class(obj, serializer_class, &block)
        end
      end

    end
  end
end