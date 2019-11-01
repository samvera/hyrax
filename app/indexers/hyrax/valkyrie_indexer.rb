# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # Transforms {Valkyrie::Resource} models to solr-ready key-value hashes. Use
  # `#to_solr` to retrieve the indexable hash.
  #
  # The default {Hyrax::ValkyrieIndexer} implementation provides minimal
  # indexing for the Valkyrie id and the reserved `#created_at` and
  # `#updated_at` attributes.
  #
  # Custom indexers inheriting from others are responsible for providing a full
  # index hash. A common pattern for doing this is to employ method composition
  # to retrieve the parent's data, then modify it:
  # `def to_solr; super.tap { |index_hash| transform(index_hash) }; end`.
  # This technique creates infinitely composible index building behavior, with
  # indexers that can always see the state of the resource and the full current
  # index document.
  #
  # It's recommended to *never* modify the state of `resource` in an indexer.
  #
  # @example defining a custom indexer with composition
  #   class MyIndexer < ValkyrieIndexer
  #     def to_solr
  #       super.tap do |index_hash|
  #         index_hash['my_field_tesim']   = resource.my_field.map(&:to_s)
  #         index_hash['other_field_ssim'] = resource.other_field
  #       end
  #     end
  #   end
  #
  # @see Valkyrie::Indexing::Solr::IndexingAdapter
  class ValkyrieIndexer
    ##
    # @!attribute [r] resource
    #   @return [Valkyrie::Resource]
    attr_reader :resource

    ##
    # @param [Valkyrie::Resource] resource
    #
    # @return [#to_solr]
    def self.for(resource:)
      ValkyrieIndexer.new(resource: resource)
    end

    ##
    # @param [Valkyrie::Resource] resource
    def initialize(resource:)
      @resource = resource
    end

    ##
    # @return [Hash<String, Object>]
    def to_solr
      {
        "id": resource.id.to_s,
        "created_at_dtsi": resource.created_at,
        "updated_at_dtsi": resource.updated_at
      }
    end
  end
end
