# frozen_string_literal: true

require 'wings/value_mapper'

module Wings
  # we really want a class var here. maybe we could use a singleton instead?
  # rubocop:disable Style/ClassVars
  class ResourceFactory
    class ResourceClassCache
      attr_reader :cache

      def initialize
        @cache = {}
      end

      def fetch(key)
        @cache.fetch(key) do
          @cache[key] = yield
        end
      end
    end

    @@resource_class_cache = ResourceClassCache.new

    attr_accessor :pcdm_object

    # The method signature is to conform to Valkyrie's method signature for
    # ::Valkyrie.config.resource_class_resolver
    def self.convert_class_name_to_valkyrie_resource_class(class_name)
      klass = class_name.constantize
      to_valkyrie_resource_class(klass: klass)
    end

    def self.to_valkyrie_resource_class(klass:)
      Class.new(ActiveFedoraResource) do
        # Based on Valkyrie implementation, we call Class.to_s to define
        # the internal resource.
        @to_s = klass.to_s
        def self.to_s
          @to_s
        end
        klass.properties.each_key do |property_name|
          attribute property_name.to_sym, ::Valkyrie::Types::String
        end
        relationship_keys = klass.reflections.keys.reject { |k| k.to_s.include?('id') }.map { |k| k.to_s.singularize + '_ids' }
        relationship_keys.each do |linked_property_name|
          attribute linked_property_name.to_sym, ::Valkyrie::Types::Set.of(::Valkyrie::Types::ID)
        end
      end
    end

    def initialize(pcdm_object:)
      self.pcdm_object = pcdm_object
    end

    def self.for(pcdm_object)
      new(pcdm_object: pcdm_object).build
    end

    def build
      klass = @@resource_class_cache.fetch(pcdm_object) do
        self.class.to_valkyrie_resource_class(klass: pcdm_object.class)
      end
      klass.new(alternate_ids: [Valkyrie::ID.new(pcdm_object.id)], **attributes)
    end

    class ActiveFedoraResource < Valkyrie::Resource
      attribute :alternate_ids, Valkyrie::Types::Array
    end

    private

      def attributes
        relationship_keys = pcdm_object.reflections.keys.reject { |k| k.to_s.include?('id') }.map { |k| k.to_s.singularize + '_ids' }

        attrs_with_relationships = pcdm_object.attributes.keys + relationship_keys

        attrs_with_relationships.each_with_object({}) do |attr_name, mem|
          next unless pcdm_object.respond_to? attr_name
          mem[attr_name.to_sym] = ValueMapper.for(pcdm_object.public_send(attr_name)).result
        end
      end
  end
  # rubocop:enable Style/ClassVars
end
