# frozen_string_literal: true
module Hyrax
  class AdminSetIndexer < ActiveFedora::IndexingService
    include Hyrax::IndexesThumbnails

    self.thumbnail_path_service = Hyrax::CollectionThumbnailPathService

    def generate_solr_document
      super.tap do |solr_doc|
        # Makes Admin Sets show under the "Admin Sets" tab
        solr_doc['generic_type_sim']        = ['Admin Set']
        solr_doc['alternative_title_tesim'] = object.alternative_title
        solr_doc['creator_ssim']            = object.creator
        solr_doc['description_tesim']       = object.description
        solr_doc['title_tesim']             = object.title
        solr_doc['title_sim']               = object.title
      end
    end
  end
end
