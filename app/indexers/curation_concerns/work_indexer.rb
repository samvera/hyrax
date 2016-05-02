module CurationConcerns
  class WorkIndexer < ActiveFedora::IndexingService
    include IndexesThumbnails
    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc[Solrizer.solr_name('member_ids', :symbol)] = object.member_ids
        Solrizer.set_field(solr_doc, 'generic_type', 'Work', :facetable)
      end
    end
  end
end
