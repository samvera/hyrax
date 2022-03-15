# frozen_string_literal: true
module Hyrax
  module ThumbnailIndexer
    extend ActiveSupport::Concern

    included do
      class_attribute :thumbnail_path_service
      self.thumbnail_path_service = ThumbnailPathService
      class_attribute :thumbnail_field
      self.thumbnail_field = :thumbnail_path_ss
    end

    # Adds thumbnail indexing to the solr document of a valkyrie resource
    def to_solr
      super.tap do |solr_doc|
        index_thumbnails(solr_doc)
      end
    end

    # Write the thumbnail paths into the solr_document
    # @param [Hash] solr_document the solr document to add the field to
    def index_thumbnails(solr_document)
      solr_document[thumbnail_field] = thumbnail_path.to_s
    end

    # Returns the value for the thumbnail path to put into the solr document
    def thumbnail_path
      self.class.thumbnail_path_service.call(resource)
    end
  end
end
