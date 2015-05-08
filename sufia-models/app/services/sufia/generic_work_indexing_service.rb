module Sufia
  class GenericWorkIndexingService < ActiveFedora::IndexingService

    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc[Solrizer.solr_name('collection_ids')] = object.collection_ids
      end
    end

  end
end
