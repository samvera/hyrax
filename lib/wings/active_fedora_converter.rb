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
      active_fedora_class.new(normal_attributes).tap do |af_object|
        af_object.id = id unless id.empty?
        add_access_control_attributes(af_object)
        apply_depositor_to(af_object)
        convert_members(af_object)
        convert_member_of_collections(af_object)
        convert_files(af_object)
      end
    end

    def active_fedora_class
      klass = resource.internal_resource.constantize

      return klass if klass <= ActiveFedora::Base

      ModelRegistry.lookup(klass) || DefaultWork
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

    # A dummy work class for valkyrie resources that don't have corresponding
    # hyrax ActiveFedora::Base models.
    #
    # A possible improvement would be to dynamically generate properties based
    # on what's found in the resource.
    class DefaultWork < ActiveFedora::Base
      include Hyrax::WorkBehavior
      property :ordered_authors, predicate: ::RDF::Vocab::DC.creator
      property :ordered_nested, predicate: ::RDF::URI("http://example.com/ordered_nested")
      property :nested_resource, predicate: ::RDF::URI("http://example.com/nested_resource"), class_name: "Wings::ActiveFedoraConverter::NestedResource"
      include ::Hyrax::BasicMetadata
      accepts_nested_attributes_for :nested_resource

      # self.indexer = <%= class_name %>Indexer
    end

    class NestedResource < ActiveTriples::Resource
      property :title, predicate: ::RDF::Vocab::DC.title
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

      def convert_members(af_object)
        return unless resource.respond_to?(:member_ids) && resource.member_ids
        # TODO: It would be better to find a way to add the members without resuming all the member AF objects
        af_object.ordered_members = resource.member_ids.map { |valkyrie_id| ActiveFedora::Base.find(valkyrie_id.id) }
      end

      def convert_member_of_collections(af_object)
        return unless resource.respond_to?(:member_of_collection_ids) && resource.member_of_collection_ids
        # TODO: It would be better to find a way to set the parent collections without resuming all the collection AF objects
        af_object.member_of_collections = resource.member_of_collection_ids.map { |valkyrie_id| ActiveFedora::Base.find(valkyrie_id.id) }
      end

      def convert_files(af_object)
        return unless resource.respond_to? :file_ids
        af_object.files = resource.file_ids.map do |fid|
          pcdm_file = Hydra::PCDM::File.new(fid.id)
          assign_association_target(af_object, pcdm_file)
        end
      end

      def assign_association_target(af_object, pcdm_file)
        case pcdm_file.metadata_node.type
        when ->(types) { types.include?(RDF::URI.new('http://pcdm.org/use#OriginalFile')) }
          af_object.association(:original_file).target = pcdm_file
        when ->(types) { types.include?(RDF::URI.new('http://pcdm.org/use#ExtractedText')) }
          af_object.association(:extracted_text).target = pcdm_file
        when ->(types) { types.include?(RDF::URI.new('http://pcdm.org/use#Thumbnail')) }
          af_object.association(:thumbnail).target = pcdm_file
        else
          pcdm_file
        end
      end

      # Normalizes the attributes parsed from the resource
      #   (This ensures that scalar values are passed to the constructor for the
      #   ActiveFedora::Base Class)
      # @return [Hash]
      def normal_attributes
        attributes.each_with_object({}) do |(attr, value), hash|
          property = active_fedora_class.properties[attr.to_s]
          # This handles some cases where the attributes do not directly map to an RDF property value
          hash[attr] = value
          next if property.nil?
          hash[attr] = Array.wrap(value) if property.multiple?
        end
      end

      def apply_depositor_to(af_object)
        af_object.apply_depositor_metadata(attributes[:depositor]) unless attributes[:depositor].blank?
      end

      # Add attributes from resource which aren't AF properties into af_object
      def add_access_control_attributes(af_object)
        return unless af_object.is_a? Hydra::AccessControl
        cache = af_object.permissions.to_a

        # if we've saved this before, it has a cache that won't clear
        # when setting permissions! we need to reset it manually and
        # rewrite with the values already in there, or saving will fail
        # to delete cached items
        af_object.permissions.reset if af_object.persisted?

        af_object.permissions = cache.map do |permission|
          permission.access_to_id = resource.try(:access_to)&.id
          permission
        end
      end
  end
end
