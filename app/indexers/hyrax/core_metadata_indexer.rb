# frozen_string_literal: true

module Hyrax
  ##
  # Indexes Hyrax Core Metadata from Valkyrie
  module CoreMetadataIndexer
    ##
    # @return [Hash<Symbol, Object>]
    def to_solr
      super.tap do |index_document|
        index_document[:title_sim]   = resource.try(:title)
        index_document[:title_tesim] = index_document[:title_sim]
      end
    end
  end
end
