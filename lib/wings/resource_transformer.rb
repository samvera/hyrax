# frozen_string_literal: true

require 'wings/converter_value_mapper'
require 'wings/active_fedora_attributes'

module Wings
  class PCDMObjectClassCache
    include Singleton

    ##
    # @!attribute [r] cache
    #   @return [Hash<Class, Class>]
    attr_reader :cache

    def initialize
      @cache = {}
    end

    ##
    # @param key [Class] the ActiveFedora class to map
    #
    # @return [Class]
    def fetch(key)
      @cache.fetch(key) do
        @cache[key] = yield
      end
    end
  end

  # This needs to be reconciled with ActiveFedoraAttributes
  class AttributeTransformer
    def self.value_mapper_class
      ConverterValueMapper
    end

    def self.run(obj, keys)
      keys.each_with_object({}) do |attr_name, mem|
        next unless obj.respond_to? attr_name
        mem[attr_name.to_sym] = value_mapper_class.for(obj.public_send(attr_name)).result
      end
    end
  end

  class DefaultWork < ActiveFedora::Base
    include Hyrax::WorkBehavior
    property :ordered_authors, predicate: ::RDF::Vocab::DC.creator
    property :ordered_nested, predicate: ::RDF::URI("http://example.com/ordered_nested")
    property :nested_resource, predicate: ::RDF::URI("http://example.com/nested_resource"), class_name: "Wings::ActiveFedoraConverter::NestedResource"
    accepts_nested_attributes_for :nested_resource

    include ::Hyrax::BasicMetadata
  end

  class ResourceTransformer
    # Construct an ActiveFedora Model from a Valkyrie Resource
    # @param valkyrie_resource [Valkyrie::Resource]
    # @return [ActiveFedora::Base]
    def self.for(valkyrie_resource)
      new(valkyrie_resource: valkyrie_resource).build
    end

    def self.class_namespace
      Wings::ResourceTransformer
    end

    def self.class_in_namespace?(class_name)
      namespaced = class_name.split("::")
      class_name.include?(class_namespace.to_s) && class_namespace.constants.include?(namespaced.last.to_sym)
    end

    def self.active_fedora_model?(class_name)
      klass = class_name.constantize
      klass.ancestors.include?(ActiveFedora::Base)
    end

    # Dynamically define the Class for the new ActiveFedora Model
    # @param resource [Valkyrie::Resource]
    # @return [Class]
    def self.to_active_fedora_class(resource:)
      return resource.internal_resource.constantize if const_defined?(resource.internal_resource) && class_in_namespace?(resource.internal_resource) || active_fedora_model?(resource.internal_resource)

      # This handles cases where there might be an ActiveFedora Model defined in
      # the global namespace
      class_name = resource.internal_resource.split("::").last
      return class_name.constantize if const_defined?(class_name) && active_fedora_model?(class_name)

      namespaced_class_name = "#{class_namespace}::#{class_name}"
      class_namespace.class_eval <<-CODE
        class #{namespaced_class_name} < Wings::DefaultWork; end
      CODE

      namespaced_class_name.to_s.constantize
    end

    # Retrieve the Class for the Valkyrie Resource being transformed
    # (Abstract and only delegates to a method supporting the transformation to
    # an ActiveFedora Model)
    # @param resource [Valkyrie::Resource]
    # @return [Class]
    def self.to_pcdm_object_class(resource:)
      to_active_fedora_class(resource: resource)
    end

    ##
    # @!attribute [rw] valkyrie_resource
    #   @return [Valkyrie::Resource]
    attr_accessor :valkyrie_resource

    ##
    # Constructor
    # @param valkyrie_resource [Valkyrie::Resource]
    def initialize(valkyrie_resource:)
      self.valkyrie_resource = valkyrie_resource
    end

    # Factory
    # Constructs the ActiveFedora Model object using a dynamically-defined child
    # class derived from ActiveFedora::Base
    # @return [ActiveFedora::Base]
    def build
      klass.new(**attributes)
    end

    private

      def klass
        @klass ||= PCDMObjectClassCache.instance.fetch(valkyrie_resource) do
          self.class.to_pcdm_object_class(resource: valkyrie_resource)
        end
      end

      # Transform the attributes from the Valkyrie Resource
      # @return [Hash]
      def transformed_attributes
        new_attributes = ActiveFedoraAttributes.new(valkyrie_resource.attributes)
        new_attributes.result
      end

      def normalized_attributes
        # This normalizes for cases where scalar values are passed to multiple
        # values for the construction of ActiveFedora Models
        normalized = {}
        transformed_attributes.each_pair do |attrib, value|
          property = klass.properties[attrib.to_s]
          # This handles some cases where the attributes do not directly map to
          # a RDF property value
          normalized[attrib] = value
          next if property.nil?
          normalized[attrib] = Array.wrap(value) if property.multiple?
        end
        normalized
      end

      alias attributes normalized_attributes
  end
end
