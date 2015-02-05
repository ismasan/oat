# http://stateless.co/hal_specification.html
module Oat
  module Adapters
    class HAL < Oat::Adapter
      def link(rel, opts = {})
        if opts.is_a?(Array)
          data[:_links][rel] = opts.select { |link_obj| link_obj.include?(:href) }
        else
          data[:_links][rel] = opts if opts[:href]
        end
      end

      def properties(&block)
        data.merge! yield_props(&block)
      end

      def property(key, value)
        data[key] = value
      end

      alias_method :meta, :property

      def rel(rels)
        # no-op to maintain interface compatibility with the Siren adapter
      end

      def entity(name, obj, serializer_class = nil, context_options = {}, &block)
        entity_serializer = serializer_from_block_or_class(obj, serializer_class, context_options, &block)
        data[:_embedded][entity_name(name)] = entity_serializer ? entity_serializer.to_hash : nil
      end

      def entities(name, collection, serializer_class = nil, context_options = {}, &block)
        data[:_embedded][entity_name(name)] = collection.map do |obj|
          entity_serializer = serializer_from_block_or_class(obj, serializer_class, context_options, &block)
          entity_serializer ? entity_serializer.to_hash : nil
        end
      end
      alias_method :collection, :entities

      def entity_name(name)
        # entity name may be an array, but HAL only uses the first
        name.respond_to?(:first) ? name.first : name
      end

      private :entity_name

    end
  end
end
