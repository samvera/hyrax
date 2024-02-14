# frozen_string_literal: true

module Hyrax
  module Indexers
    ##
    # Indexes properties common to PCDM Collections
    class PcdmCollectionIndexer < Hyrax::Indexers::ResourceIndexer
      include Hyrax::PermissionIndexer
      include Hyrax::VisibilityIndexer
      include Hyrax::LocationIndexer
      include Hyrax::ThumbnailIndexer
      include Hyrax::Indexer(:core_metadata)

      self.thumbnail_path_service = CollectionThumbnailPathService

      def to_solr
        super.tap do |index_document|
          index_document[Hyrax.config.collection_type_index_field.to_sym] = Array(resource.try(:collection_type_gid)&.to_s)
          index_document[:generic_type_sim] = ['Collection']
          index_document[:member_of_collection_ids_ssim] = resource.member_of_collection_ids.map(&:to_s)
          index_document[:depositor_ssim] = [resource.depositor]
          index_document[:depositor_tesim] = [resource.depositor]
        end
      end
    end
  end
end
