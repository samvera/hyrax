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
