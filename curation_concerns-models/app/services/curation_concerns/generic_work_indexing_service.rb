module Sufia
  class GenericWorkIndexingService < Hydra::PCDM::ObjectIndexer

    def generate_solr_document
      # leaving this in place since I know we will want to add generic files into the work's solr index
      super.tap do |solr_doc|
        solr_doc[Solrizer.solr_name('generic_files')] = object.generic_file_ids
      end
    end

  end
end
