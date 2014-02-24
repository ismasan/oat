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
        @root_name = types.first.to_s.pluralize.to_sym
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
        ent = serializer_from_block_or_class(obj, serializer_class, context_options, &block)
        entity_hash[name.to_s.pluralize.to_sym] ||= []
        if ent
          link name, :href => ent[:id]
          entity_hash[name.to_s.pluralize.to_sym] << ent
        end
      end

      def entities(name, collection, serializer_class = nil, context_options = {}, &block)
        link_name = name.to_s.pluralize.to_sym
        data[:links][link_name] = []

        collection.each do |obj|
          entity_hash[link_name] ||= []
          ent = serializer_from_block_or_class(obj, serializer_class, context_options, &block)
          if ent
            data[:links][link_name] << ent[:id]
            entity_hash[link_name] << ent
          end
        end
      end

      def collection(name, collection, serializer_class = nil, context_options = {}, &block)
        @treat_as_resource_collection = true
        data[:resource_collection] = [] unless data[:resource_collection].is_a?(Array)

        collection.each do |obj|
          ent = serializer_from_block_or_class(obj, serializer_class, context_options, &block)
          data[:resource_collection] << ent if ent
        end
      end

      def to_hash
        raise "JSON API entities MUST define a type. Use type 'user' in your serializers" unless root_name
        if serializer.top != serializer
          return data
        else
          h = {}
          if @treat_as_resource_collection
            h[root_name] = data[:resource_collection]
          else
            h[root_name] = [data]
          end
          h[:linked] = @entities if @entities.keys.any?
          return h
        end
      end

      protected

      attr_reader :root_name

      def entity_hash
        if serializer.top == serializer
          @entities
        else
          serializer.top.adapter.entity_hash
        end
      end

    end
  end
end
