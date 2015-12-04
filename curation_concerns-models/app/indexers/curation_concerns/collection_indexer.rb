module CurationConcerns
  class CollectionIndexer < Hydra::PCDM::CollectionIndexer
    STORED_INTEGER = Solrizer::Descriptor.new(:integer, :stored)
    def generate_solr_document
      super.tap do |solr_doc|
        # Makes Collections show under the "Collections" tab
        Solrizer.set_field(solr_doc, 'generic_type', 'Collection', :facetable)
        # Index the size of the collection in bytes
        solr_doc[Solrizer.solr_name(:bytes, STORED_INTEGER)] = object.bytes
      end
    end
  end
end
