# frozen_string_literal: true
module Hyrax
  # This module can be mixed in on an indexer in order to index the basic metadata fields
  module IndexesBasicMetadata
    # We're overriding a method from ActiveFedora::IndexingService
    def rdf_service
      BasicMetadataIndexer
    end
  end
end
