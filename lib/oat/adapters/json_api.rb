# http://jsonapi.org/format/#url-based-json-api
require 'active_support/inflector'
require 'active_support/core_ext/string/inflections'
unless defined?(String.new.pluralize)
  class String
    include ActiveSupport::CoreExtensions::String::Inflections
  end
end

module Oat
  module Adapters
    class JsonAPI < Oat::Adapter

      def initialize(*args)
        super
        @entities = {}
      end

      def type(*types)
        @root_name = types.first.to_s
      end

      def link(rel, opts = {})
        data[:links][rel] = opts[:href]
      end

      def properties(&block)
        data.merge! yield_props(&block)
      end

      def property(key, value)
        data[key] = value
      end

      def entity(name, obj, serializer_class = nil, context_options = {}, &block)
        @entities[name.to_s.pluralize.to_sym] ||= []
        ent = entity_without_root(obj, serializer_class, context_options, &block)
        if ent
          link name, :href => ent[:id]
          @entities[name.to_s.pluralize.to_sym] << ent
        end
      end

      def entities(name, collection, serializer_class = nil, context_options = {}, &block)
        link_name = name.to_s.pluralize.to_sym
        data[:links][link_name] = []

        collection.each do |obj|
          @entities[link_name] ||= []
          ent = entity_without_root(obj, serializer_class, context_options, &block)
          if ent
            data[:links][link_name] << ent[:id]
            @entities[link_name] << ent
          end
        end
      end

      def to_hash
        raise "JSON API entities MUST define a type. Use type 'user' in your serializers" unless root_name
        h = {root_name.pluralize.to_sym => [data]}
        h[:linked] = @entities if @entities.keys.any?
        h
      end

      protected

      attr_reader :root_name

      def entity_without_root(obj, serializer_class = nil, context_options = {}, &block)
        ent = serializer_from_block_or_class(obj, serializer_class, context_options, &block)
        ent.values.first.first if ent
      end

    end
  end
end
