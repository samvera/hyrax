# frozen_string_literal: true

module Hyrax
  ##
  # Indexes properties common to PCDM Collections
  class PcdmCollectionIndexer < Hyrax::ValkyrieIndexer
    include Hyrax::ResourceIndexer
    include Hyrax::PermissionIndexer
    include Hyrax::VisibilityIndexer
    include Hyrax::Indexer(:collection_core_metadata)
    include Hyrax::Indexer(:collection_basic_metadata)
    include Hyrax::Indexer(:collection_metadata)

    def to_solr
      super.tap do |index_document|
        index_document[Hyrax.config.collection_type_index_field.to_sym] = Array(resource.try(:collection_type_gid)&.to_s)
        index_document[:generic_type_sim] = ['Collection']
        index_document[:thumbnail_path_ss] = Hyrax::CollectionThumbnailPathService.call(resource)
      end
    end
  end
end
