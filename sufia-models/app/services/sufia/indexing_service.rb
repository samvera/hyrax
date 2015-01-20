module Sufia
  class IndexingService < ActiveFedora::IndexingService

    # Unstemmed, searchable, stored
    def self.noid_indexer
      @noid_indexer ||= Solrizer::Descriptor.new(:text, :indexed, :stored)
    end

    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc[Solrizer.solr_name("noid", Sufia::IndexingService.noid_indexer)] = object.noid
      end
    end
  end
end
