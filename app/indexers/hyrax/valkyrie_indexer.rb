# frozen_string_literal: true

module Hyrax
  ##
  # @see Valkyrie::Indexing::Solr::IndexingAdapter
  class ValkyrieIndexer
    ##
    # @!attribute [r] resource
    #   @return [Valkyrie::Resource]
    attr_reader :resource

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
