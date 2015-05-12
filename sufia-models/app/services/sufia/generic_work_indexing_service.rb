module Sufia
  class GenericWorkIndexingService < ActiveFedora::IndexingService

    def generate_solr_document
      # leaving this in place since I know we will want to add generic files into the work's solr index
      super
    end

  end
end
