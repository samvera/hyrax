module CurationConcerns
  class CollectionIndexer < Hydra::PCDM::CollectionIndexer
    def generate_solr_document
      super.tap do |solr_doc|
        # Makes Collections show under the "Collections" tab
        Solrizer.set_field(solr_doc, 'generic_type', 'Collection', :facetable)
      end
    end
  end
end
