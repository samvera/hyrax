# frozen_string_literal: true

module Hyrax
  ##
  # Indexes properties common to PCDM Collections
  class PcdmCollectionIndexer < Hyrax::ValkyrieIndexer
    include Hyrax::ResourceIndexer
    include Hyrax::PermissionIndexer
    include Hyrax::VisibilityIndexer
    include Hyrax::ThumbnailIndexer
    include Hyrax::Indexer(:core_metadata)

    self.thumbnail_path_service = CollectionThumbnailPathService

    def to_solr
      super.tap do |index_document|
        index_document[Hyrax.config.collection_type_index_field.to_sym] = Array(resource.try(:collection_type_gid)&.to_s)
        index_document[:generic_type_sim] = ['Collection']
        index_document[:depositor_ssim] = [resource.depositor]
        index_document[:depositor_tesim] = [resource.depositor]
      end
    end
  end
end
