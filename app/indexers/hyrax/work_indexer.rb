# frozen_string_literal: true
module Hyrax
  class WorkIndexer < ActiveFedora::IndexingService
    include Hyrax::IndexesThumbnails
    include Hyrax::IndexesWorkflow

    self.thumbnail_path_service = Hyrax::WorkThumbnailPathService
    def generate_solr_document
      super.tap do |solr_doc|
        solr_doc['member_ids_ssim'] = object.member_ids
        solr_doc['member_of_collections_ssim']    = object.member_of_collections.map(&:first_title)
        solr_doc['member_of_collection_ids_ssim'] = object.member_of_collections.map(&:id)
        solr_doc['generic_type_sim'] = ['Work']

        # This enables us to return a Work when we have a FileSet that matches
        # the search query.  While at the same time allowing us not to return Collections
        # when a work in the collection matches the query.
        # NOTE: file_set_ids_ssim is not indexed for valkyrie resources
        solr_doc['file_set_ids_ssim'] = solr_doc['member_ids_ssim']
        solr_doc['visibility_ssi'] = object.visibility

        admin_set_label = object.admin_set.to_s
        solr_doc['admin_set_sim']   = admin_set_label
        solr_doc['admin_set_tesim'] = admin_set_label
      end
    end
  end
end
