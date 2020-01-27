# frozen_string_literal: true

module Hyrax
  ##
  # Indexes properties common to PCDM Collections
  class ValkyrieCollectionIndexer < Hyrax::ValkyrieIndexer
    Hyrax::ValkyrieIndexer.register self, as_indexer_for: Hyrax::PcdmCollection

    include Hyrax::ResourceIndexer
    include Hyrax::PermissionIndexer
    include Hyrax::VisibilityIndexer

    def to_solr
      super.tap do |index_document|
        index_document[:generic_type_sim] = ['Collection']
        index_document[:thumbnail_path_ss] = Hyrax::CollectionThumbnailPathService.call(resource)
      end
    end
  end
end
