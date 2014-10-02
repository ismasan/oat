# http://stateless.co/hal_specification.html
module Oat
  module Adapters
    class HAL < Oat::Adapter
      def initialize(serializer)
        super
        @data = Hash.new
        [:_links, :_embedded].each do |key|
          data[key] = {}
        end
      end

      def link(rel, opts = {})
        data[:_links][rel] = opts if opts[:href]
      end

      def properties(&block)
        data.merge! yield_props(&block)
      end

      def property(key, value)
        data[key] = value
      end

      alias_method :meta, :property

      def entity(name, obj, serializer_class = nil, context_options = {}, &block)
        entity_serializer = serializer_from_block_or_class(obj, serializer_class, context_options, &block)
        data[:_embedded][name] = entity_serializer
      end

      def entities(name, collection, serializer_class = nil, context_options = {}, &block)
        data[:_embedded][name] = collection.map do |obj|
          serializer_from_block_or_class(obj, serializer_class, context_options, &block)
        end
      end
      alias_method :collection, :entities

    end
  end
end
