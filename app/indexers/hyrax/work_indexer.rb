module Hyrax
  class WorkIndexer < ActiveFedora::IndexingService
    include Hyrax::IndexesThumbnails
    include Hyrax::IndexesWorkflow

    self.thumbnail_path_service = Hyrax::WorkThumbnailPathService
    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc['member_ids_ssim'] = object.member_ids
        solr_doc['member_of_collections_ssim']    = collection_names
        solr_doc['member_of_collection_ids_ssim'] = object.member_of_collection_ids
        Solrizer.set_field(solr_doc, 'generic_type', 'Work', :facetable)

        # This enables us to return a Work when we have a FileSet that matches
        # the search query.  While at the same time allowing us not to return Collections
        # when a work in the collection matches the query.
        solr_doc['file_set_ids_ssim'] = solr_doc['member_ids_ssim']
        solr_doc['visibility_ssi'] = object.visibility

        admin_set_label = object.admin_set.to_s
        solr_doc['admin_set_sim']   = admin_set_label
        solr_doc['admin_set_tesim'] = admin_set_label
      end
    end

    private

      def collection_names
        object.member_of_collection_ids.map do |id|
          Hyrax::Queries.find_by(id: id).first_title
        end
      end
  end
end
