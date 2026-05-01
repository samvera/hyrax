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
      include Hyrax::Indexer(:core_metadata) if Hyrax.config.collection_include_metadata?
      include Hyrax::Indexers::RedirectsIndexer if Hyrax.config.redirects_enabled?
      check_if_flexible(Hyrax::PcdmCollection)

      self.thumbnail_path_service = CollectionThumbnailPathService

      def to_solr
        super.tap do |index_document|
          index_document[Hyrax.config.collection_type_index_field.to_sym] = Array(resource.try(:collection_type_gid)&.to_s)
          index_document[:generic_type_sim] = ['Collection']
          index_document[:member_of_collection_ids_ssim] = resource.member_of_collection_ids.map(&:to_s)
          index_document[:depositor_ssim] = [resource.depositor]
          index_document[:depositor_tesim] = [resource.depositor]
          index_document['thumbnail_alt_text_tesim'] = thumbnail_alt_text(resource.id.to_s)
        end
      end

      private

      def thumbnail_alt_text(collection_id)
        branding = CollectionBrandingInfo.where(collection_id: collection_id, role: "thumbnail").first
        branding&.alt_text.presence
      end
    end
  end
end
