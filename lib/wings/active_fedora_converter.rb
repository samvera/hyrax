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
      attributes = ActiveFedoraAttributes.new(resource.attributes).result
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

    class ActiveFedoraAttributes
      attr_reader :attributes
      def initialize(attributes)
        @attributes = attributes
      end

      def result
        Hash[
          filter_attributes.map do |value|
            ConverterValueMapper.for(value).result
          end.select(&:present?)
        ]
      end

      ##
      # @return [Hash<Symbol, Object>]
      def filter_attributes
        # avoid reflections for now; `*_ids` can't be passed as attributes.
        # handling for reflections needs to happen in future work
        attrs = attributes.reject { |k, _| k.to_s.end_with? '_ids' }

        [:internal_resource, :new_record, :id, :alternate_ids, :created_at,
         :updated_at, :member_ids]
          .map { |key| attrs.delete(key) }

        [:admin_set_id, :embargo_id, :lease_id, :access_control_id]
          .map { |name| stringify_id_field(attrs, name: name) }

        attrs.compact
      end

      private

        def stringify_id_field(attrs, name:)
          value       = attrs.delete(name)
          attrs[name] = value.to_s unless value.nil? || value.empty?
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

    class ConverterValueMapper < ::Valkyrie::ValueMapper; end

    class NestedResourceArrayValue < ::Valkyrie::ValueMapper
      ConverterValueMapper.register(self)
      def self.handles?(value)
        value.last.is_a?(Array) && value.last.map { |x| x.try(:class) }.include?(Hash)
      end

      def result
        ["#{value.first}_attributes".to_sym, values]
      end

      def values
        value.last.map do |val|
          calling_mapper.for([value.first, val]).result
        end.flat_map(&:last)
      end
    end

    class NestedResourceValue < ::Valkyrie::ValueMapper
      ConverterValueMapper.register(self)
      def self.handles?(value)
        value.last.is_a?(Hash)
      end

      def result
        # [value.first, ActiveFedoraConverter.new(resource: value.last).convert]
        attrs = ActiveFedoraAttributes.new(value.last).result
        attrs.delete(:read_groups)
        attrs.delete(:read_users)
        attrs.delete(:edit_groups)
        attrs.delete(:edit_users)

        [value.first, attrs]
      end
    end

    private

      def convert_members(af_object)
        return unless resource.respond_to?(:member_ids) && resource.member_ids
        # TODO: It would be better to find a way to add the members without resuming all the member AF objects
        resource.member_ids.each { |valkyrie_id| af_object.ordered_members << ActiveFedora::Base.find(valkyrie_id.id) }
      end

      def convert_member_of_collections(af_object)
        return unless resource.respond_to?(:member_of_collection_ids) && resource.member_of_collection_ids
        # TODO: It would be better to find a way to set the parent collections without resuming all the collection AF objects
        resource.member_of_collection_ids.each { |valkyrie_id| af_object.member_of_collections << ActiveFedora::Base.find(valkyrie_id.id) }
      end
  end
end
