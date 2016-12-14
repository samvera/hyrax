module Hyrax
  class WorkIndexer < ActiveFedora::IndexingService
    include Hyrax::IndexesThumbnails
    include Hyrax::IndexesWorkflow

    self.thumbnail_path_service = Hyrax::WorkThumbnailPathService
    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc[Solrizer.solr_name('member_ids', :symbol)] = object.member_ids
        solr_doc[Solrizer.solr_name('member_of_collections', :symbol)] = object.member_of_collections.map(&:first_title)
        solr_doc[Solrizer.solr_name('member_of_collection_ids', :symbol)] = object.member_of_collections.map(&:id)
        Solrizer.set_field(solr_doc, 'generic_type', 'Work', :facetable)

        # This enables us to return a Work when we have a FileSet that matches
        # the search query.  While at the same time allowing us not to return Collections
        # when a work in the collection matches the query.
        solr_doc[Solrizer.solr_name('file_set_ids', :symbol)] = solr_doc[Solrizer.solr_name('member_ids', :symbol)]

        admin_set_label = object.admin_set.to_s
        solr_doc[Solrizer.solr_name('admin_set', :facetable)] = admin_set_label
        solr_doc[Solrizer.solr_name('admin_set', :stored_searchable)] = admin_set_label
      end
    end
  end
end
