# frozen_string_literal: true
require 'wings/resource_transformer'

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
    class NestedResource < ::Wings::NestedResource; end

    ##
    # Accesses the Class implemented for handling resource attributes
    # @return [Class]
    def self.attributes_class
      ActiveFedoraAttributes
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
    # @return [Hash]
    def attributes
      @attribs ||= begin
        wrapper = self.class.attributes_class.new(resource.attributes)
        wrapper.result
      end
    end

    ##
    # @return [ActiveFedora::Base]
    def convert
      ResourceTransformer.for(resource).tap do |af_object|
        af_object.id = id unless id.empty?
        apply_depositor_to(af_object)
        add_access_control_attributes(af_object)
        af_object.visibility = resource.attributes[:visibility] unless resource.attributes[:visibility].blank?
        convert_members(af_object)
        convert_member_of_collections(af_object)
      end
    end

    ##
    # In the context of a Valkyrie resource, prefer to use the id if it
    # is provided and fallback to the first of the alternate_ids. If all else fails
    # then the id hasn't been minted and shouldn't yet be set.
    # @return [String]
    def id
      id_attr = resource[:id]
      return id_attr.to_s if id_attr.present? && id_attr.is_a?(::Valkyrie::ID) && !id_attr.blank?
      return "" unless resource.respond_to?(:alternate_ids)
      resource.alternate_ids.first.to_s
    end

    private

      def convert_members(af_object)
        return unless resource.respond_to?(:member_ids) && resource.member_ids
        # TODO: It would be better to find a way to add the members without resuming all the member AF objects
        ordered_members = []
        resource.member_ids.each do |valkyrie_id|
          ordered_members << ActiveFedora::Base.find(valkyrie_id.id)
        end
        af_object.ordered_members = ordered_members
      end

      def convert_member_of_collections(af_object)
        return unless resource.respond_to?(:member_of_collection_ids) && resource.member_of_collection_ids
        # TODO: It would be better to find a way to set the parent collections without resuming all the collection AF objects
        member_of_collections = []
        resource.member_of_collection_ids.each do |valkyrie_id|
          member_of_collections << ActiveFedora::Base.find(valkyrie_id.id)
        end
        af_object.member_of_collections = member_of_collections
      end

      # Normalizes the attributes parsed from the resource
      #   (This ensures that scalar values are passed to the constructor for the
      #   ActiveFedora::Base Class)
      # @return [Hash]
      def normal_attributes
        normalized = {}
        attributes.each_pair do |attr, value|
          property = active_fedora_class.properties[attr.to_s]
          # This handles some cases where the attributes do not directly map to an
          #   RDF property value
          normalized[attr] = value
          next if property.nil?
          normalized[attr] = Array.wrap(value) if property.multiple?
        end
        normalized
      end

      def apply_depositor_to(af_object)
        af_object.apply_depositor_metadata(attributes[:depositor]) unless attributes[:depositor].blank?
      end

      # Add attributes from resource which aren't AF properties into af_object
      def add_access_control_attributes(af_object)
        af_object.visibility = attributes[:visibility] unless attributes[:visibility].blank?
        af_object.read_users = attributes[:read_users] unless attributes[:read_users].blank?
        af_object.edit_users = attributes[:edit_users] unless attributes[:edit_users].blank?
        af_object.read_groups = attributes[:read_groups] unless attributes[:read_groups].blank?
        af_object.edit_groups = attributes[:edit_groups] unless attributes[:edit_groups].blank?
      end
  end
end
