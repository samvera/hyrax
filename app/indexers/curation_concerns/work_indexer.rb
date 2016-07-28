module CurationConcerns
  class WorkIndexer < ActiveFedora::IndexingService
    include IndexesThumbnails
    include IndexesWorkflow

    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc[Solrizer.solr_name('member_ids', :symbol)] = object.member_ids
        solr_doc[Solrizer.solr_name('member_of_collections', :symbol)] = object.member_of_collections.map(&:first_title)
        solr_doc[Solrizer.solr_name('member_of_collection_ids', :symbol)] = object.member_of_collections.map(&:id)
        Solrizer.set_field(solr_doc, 'generic_type', 'Work', :facetable)
      end
    end
  end
end
