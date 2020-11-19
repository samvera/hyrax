# frozen_string_literal: true

require 'wings/converter_value_mapper'

module Wings
  ##
  # Converts `Valkyrie::Resource` objects to legacy `ActiveFedora::Base` objects.
  #
  # @example
  #   work     = GenericWork.new(title: ['Comet in Moominland'])
  #   resource = GenericWork.valkyrie_resource
  #
  #   ActiveFedoraConverter.new(resource: resource).convert == work # => true
  #
  # @note the `Valkyrie::Resource` object passed to this class **must** have an
  #   `#internal_resource` mapping it to an `ActiveFedora::Base` class.
  class ActiveFedoraConverter
    ##
    # Accesses the Class implemented for handling resource attributes
    # @return [Class]
    def self.attributes_class
      ActiveFedoraAttributes
    end

    ##
    # A class level cache mapping from Valkyrie resource classes to generated
    # ActiveFedora classes
    # @return [Hash<Class, Class>]
    def self.class_cache
      @class_cache ||= {}
    end

    ##
    # @params [Valkyrie::Resource] resource
    #
    # @return [ActiveFedora::Base]
    def self.convert(resource:)
      new(resource: resource).convert
    end

    ##
    # @!attribute [rw] resource
    #   @return [Valkyrie::Resource]
    attr_accessor :resource

    ##
    # @param [Valkyrie::Resource]
    def initialize(resource:)
      @resource = resource
    end

    ##
    # Accesses and parses the attributes from the resource through ConverterValueMapper
    #
    # @return [Hash] attributes with values mapped for building an ActiveFedora model
    def attributes
      @attributes ||= attributes_class.mapped_attributes(attributes: resource.attributes).select do |attr|
        active_fedora_class.supports_property?(attr)
      end
    end

    ##
    # @return [ActiveFedora::Base]
    def convert
      instance.tap do |af_object|
        af_object.id ||= id unless id.empty?
        apply_attributes_to_model(af_object)
      end
    end

    def active_fedora_class
      @active_fedora_class ||= # cache the class at the instance level
        begin
          klass = begin
                    resource.internal_resource.constantize
                  rescue NameError
                    Wings::ActiveFedoraClassifier.new(resource.internal_resource).best_model
                  end

          return klass if klass <= ActiveFedora::Base

          ModelRegistry.lookup(klass)
        end
    end

    ##
    # In the context of a Valkyrie resource, prefer to use the id if it
    # is provided and fallback to the first of the alternate_ids. If all else fails
    # then the id hasn't been minted and shouldn't yet be set.
    # @return [String]
    def id
      return resource[:id].to_s if resource[:id]&.is_a?(::Valkyrie::ID) && resource[:id].present?
      return "" unless resource.respond_to?(:alternate_ids)

      resource.alternate_ids.first.to_s
    end

    def self.DefaultWork(resource_class)
      class_cache[resource_class] ||= Class.new(DefaultWork) do
        self.valkyrie_class = resource_class

        # extract AF properties from the Valkyrie schema;
        # skip reserved attributes, proctected properties, and those already defined
        resource_class.schema.each do |schema_key|
          next if resource_class.reserved_attributes.include?(schema_key.name)
          next if protected_property_name?(schema_key.name)
          next if properties.keys.include?(schema_key.name.to_s)

          property schema_key.name, predicate: RDF::URI("http://hyrax.samvera.org/ns/wings##{schema_key.name}")
        end

        # nested attributes in AF don't inherit! this needs to be here until we can drop it completely.
        accepts_nested_attributes_for :nested_resource
      end
    end

    ##
    # A base model class for valkyrie resources that don't have corresponding
    # ActiveFedora::Base models.
    class DefaultWork < ActiveFedora::Base
      include Hyrax::WorkBehavior
      property :nested_resource, predicate: ::RDF::URI("http://example.com/nested_resource"), class_name: "Wings::ActiveFedoraConverter::NestedResource"

      class_attribute :valkyrie_class
      self.valkyrie_class = Hyrax::Resource

      class << self
        delegate :human_readable_type, to: :valkyrie_class

        def model_name(*)
          _hyrax_default_name_class.new(valkyrie_class)
        end

        def to_rdf_representation
          "Wings(#{valkyrie_class})"
        end
        alias inspect to_rdf_representation
        alias to_s inspect
      end

      def to_global_id
        GlobalID.create(valkyrie_class.new(id: id))
      end
    end

    class NestedResource < ActiveTriples::Resource
      property :title, predicate: ::RDF::Vocab::DC.title
      property :author, predicate: ::RDF::URI('http://example.com/ns/author')
      property :depositor, predicate: ::RDF::URI('http://example.com/ns/depositor')
      property :nested_resource, predicate: ::RDF::URI("http://example.com/nested_resource"), class_name: NestedResource
      property :ordered_authors, predicate: ::RDF::Vocab::DC.creator
      property :ordered_nested, predicate: ::RDF::URI("http://example.com/ordered_nested")

      def initialize(uri = RDF::Node.new, _parent = ActiveTriples::Resource.new)
        uri = if uri.try(:node?)
                RDF::URI("#nested_resource_#{uri.to_s.gsub('_:', '')}")
              elsif uri.to_s.include?('#')
                RDF::URI(uri)
              end
        super
      end

      include ::Hyrax::BasicMetadata
    end

    private

    def instance
      active_fedora_class.find(id)
    rescue ActiveFedora::ObjectNotFoundError
      active_fedora_class.new
    end

    def attributes_class
      self.class.attributes_class
    end

    # Normalizes the attributes parsed from the resource
    #   (This ensures that scalar values are passed to the constructor for the
    #   ActiveFedora::Base Class)
    # @return [Hash]
    def normal_attributes
      attributes.each_with_object({}) do |(attr, value), hash|
        property = active_fedora_class.properties[attr.to_s]
        hash[attr] = if property.nil?
                       value
                     elsif property.multiple?
                       Array.wrap(value)
                     elsif Array.wrap(value).length < 2
                       Array.wrap(value).first
                     else
                       value
                     end
      end
    end

    ##
    # apply attributes to the ActiveFedora model
    def apply_attributes_to_model(af_object)
      case af_object
      when Hydra::AccessControl
        add_access_control_attributes(af_object)
      else
        converted_attrs = normal_attributes
        members = converted_attrs.delete(:members)
        af_object.attributes = converted_attrs
        af_object.ordered_members = members if members
      end
    end

    # Add attributes from resource which aren't AF properties into af_object
    def add_access_control_attributes(af_object)
      normal_attributes[:permissions].each do |permission|
        permission.access_to_id = resource.access_to&.id
      end

      af_object.permissions = normal_attributes[:permissions]
    end
  end
end
