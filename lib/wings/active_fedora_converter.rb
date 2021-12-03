# frozen_string_literal: true

require 'wings/converter_value_mapper'
require 'wings/active_fedora_converter/default_work'
require 'wings/active_fedora_converter/nested_resource'

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

          return klass if klass <= ActiveFedora::Common

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

    private

    def instance
      id.present? ? active_fedora_class.find(id) : active_fedora_class.new
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
      when ActiveFedora::File
        add_file_attributes(af_object)
      else
        converted_attrs = normal_attributes
        members = Array.wrap(converted_attrs.delete(:members))
        files = converted_attrs.delete(:files)
        af_object.attributes = converted_attrs
        members.empty? ? af_object.try(:ordered_members)&.clear : af_object.try(:ordered_members=, members)
        af_object.try(:members)&.replace(members)
        af_object.files.build_or_set(files) if files
      end
    end

    # Add attributes from resource which aren't AF properties into af_object
    def add_access_control_attributes(af_object)
      normal_attributes[:permissions].each { |p| p.access_to_id = resource.access_to&.id }
      af_object.permissions = normal_attributes[:permissions]
    end

    # for files, add attributes to metadata_node, plus some other work
    def add_file_attributes(af_object)
      af_object.metadata_node.attributes = normal_attributes
      af_object.original_name = resource.original_filename
      new_type = (resource.type - af_object.metadata_node.type.to_a).first
      af_object.metadata_node.type = new_type if new_type
      af_object.mime_type = resource.mime_type
      af_object.content = resource.content unless resource.content.nil?
    end
  end
end
