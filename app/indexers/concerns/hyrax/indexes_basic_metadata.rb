module Hyrax
  module IndexesBasicMetadata
    # We're overriding a method from ActiveFedora::IndexingService
    def rdf_service
      BasicMetadataIndexer
    end
  end
end
