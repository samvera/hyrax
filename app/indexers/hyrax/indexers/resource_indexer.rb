# frozen_string_literal: true

module Hyrax
  module Indexers
    ##
    # @api public
    #
    # Transforms +Valkyrie::Resource+ models to solr-ready key-value hashes. Use
    # {#to_solr} to retrieve the indexable hash.
    #
    # The default {Hyrax::Indexers::ResourceIndexer} implementation provides
    # minimal indexing for the Valkyrie id and the reserved +#created_at+ and
    # +#updated_at+ attributes.
    #
    # Custom indexers inheriting from others are responsible for providing a
    # full index hash. A common pattern for doing this is to employ method
    # composition to retrieve the parent's data, then modify it:
    # +def to_solr; super.tap { |index_doc| transform(index_doc) }; end+.
    # This technique creates infinitely composible index building behavior, with
    # indexers that can always see the state of the resource and the full
    # current index document.
    #
    # It's recommended to *never* modify the state of +resource+ in an indexer.
    class ResourceIndexer
      ##
      # @!attribute [r] resource
      #   @api public
      #   @return [Valkyrie::Resource]
      attr_reader :resource

      ##
      # @api private
      # @param [Valkyrie::Resource] resource
      def initialize(resource:)
        @resource = resource
      end

      ##
      # @api public
      # @return [HashWithIndifferentAccess<Symbol, Object>]
      def to_solr
        {
          "id": resource.id.to_s,
          "date_uploaded_dtsi": resource.created_at,
          "date_modified_dtsi": resource.updated_at,
          "system_create_dtsi": resource.created_at,
          "system_modified_dtsi": resource.updated_at,
          "has_model_ssim": resource.to_rdf_representation,
          "human_readable_type_tesim": resource.human_readable_type,
          "human_readable_type_sim": resource.human_readable_type,
          "alternate_ids_sim": resource.alternate_ids.map(&:to_s)
        }.with_indifferent_access
      end

      ##
      # @api private
      # @note provided for ActiveFedora compatibility.
      def generate_solr_document
        to_solr.stringify_keys
      end

      class << self
        ##
        # @api public
        # @param resource [Valkyrie::Resource] an instance of a
        #   +Valkyrie::Resource+ or an inherited class
        # @note This factory will attempt to return an indexer following a
        #   naming convention where the indexer for a resource class is expected
        #   to be the class name appended with 'Indexer'. It will then attempt
        #   to select an indexer based on the class of the resource, and will
        #   return a default {Hyrax::Indexers::ResourceIndexer} if an indexer
        #   class is otherwise not found.
        #
        # @return [Hyrax::Indexers::ResourceIndexer] an instance of +Hyrax::Indexers::ResourceIndexer+ or an inherited class
        #
        # @example
        #     Hyrax::Indexers::ResourceIndexer.for(resource: Book.new) # => #<BookIndexer ...>
        def for(resource:)
          klass = "#{resource.class.name}Indexer".safe_constantize
          klass = nil unless klass.is_a?(Class) && klass.instance_methods.include?(:to_solr)
          klass ||= Hyrax::Indexers::ResourceIndexer(resource.class)
          klass.new(resource: resource)
        end
      end
    end
  end
end
