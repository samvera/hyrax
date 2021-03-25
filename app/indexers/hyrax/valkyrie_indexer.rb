# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # Transforms +Valkyrie::Resource+ models to solr-ready key-value hashes. Use
  # {#to_solr} to retrieve the indexable hash.
  #
  # The default {Hyrax::ValkyrieIndexer} implementation provides minimal
  # indexing for the Valkyrie id and the reserved +#created_at+ and
  # +#updated_at+ attributes.
  #
  # Custom indexers inheriting from others are responsible for providing a full
  # index hash. A common pattern for doing this is to employ method composition
  # to retrieve the parent's data, then modify it:
  # +def to_solr; super.tap { |index_document| transform(index_document) }; end+.
  # This technique creates infinitely composible index building behavior, with
  # indexers that can always see the state of the resource and the full current
  # index document.
  #
  # It's recommended to *never* modify the state of +resource+ in an indexer.
  #
  # @example defining a custom indexer with composition
  #   class MyIndexer < ValkyrieIndexer
  #     def to_solr
  #       super.tap do |index_document|
  #         index_document[:my_field_tesim]   = resource.my_field.map(&:to_s)
  #         index_document[:other_field_ssim] = resource.other_field
  #       end
  #     end
  #   end
  #
  # @example pairing an indexer with a model class
  #   class Book < Hyrax::Resource
  #     attribute :author
  #   end
  #
  #   # match by name "#{model_class}Indexer"
  #   class BookIndexer < ValkyrieIndexer
  #     def to_solr
  #       super.tap do |index_document|
  #         index_document[:author_si] = resource.author
  #       end
  #     end
  #   end
  #
  #   ValkyrieIndexer.for(resource: Book.new) # => #<BookIndexer:0x0000563715a9f1f8 ...>
  #
  # @see Valkyrie::Indexing::Solr::IndexingAdapter
  class ValkyrieIndexer
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
    # @return [Hash<Symbol, Object>]
    def to_solr
      {
        "id": resource.id.to_s,
        "created_at_dtsi": resource.created_at,
        "updated_at_dtsi": resource.updated_at,
        "has_model_ssim": resource.internal_resource
      }
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
      # @param resource [Valkyrie::Resource] an instance of a +Valkyrie::Resource+
      #   or an inherited class
      # @note This factory will attempt to return an indexer following a naming convention
      #   where the indexer for a resource class is expected to be the class name
      #   appended with 'Indexer'.  It will return default {ValkyrieIndexer} if
      #   an indexer class following the naming convention is not found.
      #
      # @return [Valkyrie::Indexer] an instance of ValkyrieIndexer or an inherited class based on naming convention
      #
      # @example
      #     ValkyrieIndexer.for(resource: Book.new) # => #<BookIndexer ...>
      def for(resource:)
        case resource
        when Hyrax::FileSet
          Hyrax::ValkyrieFileSetIndexer.new(resource: resource)
        else
          indexer_class_for(resource).new(resource: resource)
        end
      end

      private

      ##
      # @param [Object]
      # @return [Class]
      def indexer_class_for(resource)
        indexer_class = "#{resource.class.name}Indexer".safe_constantize

        return indexer_class if indexer_class.is_a?(Class) &&
                                indexer_class.instance_methods.include?(:to_solr)
        ValkyrieIndexer
      end
    end
  end
end
