# frozen_string_literal: true

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
    # @!attribute [rw] resource
    #   @return [Valkyrie::Resource]
    attr_accessor :resource

    ##
    # @param [Valkyrie::Resource]
    def initialize(resource:)
      @resource = resource
    end

    ##
    # @return [ActiveFedora::Base]
    def convert
      active_fedora_class.new(attributes).tap do |af_object|
        af_object.id = id unless id.empty?
        convert_members(af_object)
        convert_member_of_collections(af_object)
      end
    end

    def active_fedora_class
      klass = resource.internal_resource.constantize
      return klass if klass <= ActiveFedora::Base
      DefaultWork
    end

    ##
    # @return [Hash<Symbol, Object>]
    def attributes
      attrs = resource.attributes

      # avoid reflections for now; `*_ids` can't be passed as attributes.
      # handling for reflections needs to happen in future work
      attrs = attrs.reject { |k, _| k.to_s.end_with? '_ids' }

      attrs.delete(:internal_resource)
      attrs.delete(:new_record)
      attrs.delete(:id)
      attrs.delete(:alternate_ids)
      attrs.delete(:created_at)
      attrs.delete(:updated_at)

      embargo_id         = attrs.delete(:embargo_id)
      attrs[:embargo_id] = embargo_id.to_s unless embargo_id.nil? || embargo_id.empty?
      lease_id          = attrs.delete(:lease_id)
      attrs[:lease_id]  = lease_id.to_s unless lease_id.nil? || lease_id.empty?

      attrs.compact
    end

    ##
    # @return [String]
    def id
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
      accepts_nested_attributes_for :nested_resource

      # self.indexer = <%= class_name %>Indexer
      include ::Hyrax::BasicMetadata
    end

    class NestedResource < ActiveTriples::Resource
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
        resource.member_ids.each { |valkyrie_id| af_object.members << ActiveFedora::Base.find(valkyrie_id.id) }
      end

      def convert_member_of_collections(af_object)
        return unless resource.respond_to?(:member_of_collection_ids) && resource.member_of_collection_ids
        # TODO: It would be better to find a way to set the parent collections without resuming all the collection AF objects
        resource.member_of_collection_ids.each { |valkyrie_id| af_object.member_of_collections << ActiveFedora::Base.find(valkyrie_id.id) }
      end
  end
end
