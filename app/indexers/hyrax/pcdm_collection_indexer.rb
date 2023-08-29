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
        index_document[:member_of_collection_ids_ssim] = resource.member_of_collection_ids.map(&:to_s)
        index_document[:depositor_ssim] = [resource.depositor]
        index_document[:depositor_tesim] = [resource.depositor]
        # add all attributes that should be indexed for collections here
        tesim_and_ssim_attributes = ['abstract', 'access_right', 'alternative_title', 'based_near', 'bibliographic_citation', 'contributor', 'identifier', 'import_url', 'publisher', 'label', 'language', 'license', 'publisher', 'rights_notes', 'rights_statement', 'source', 'subject']
        tesim_and_ssim_attributes.each do |attribute|
          index_document["#{attribute}_ssim"] = resource["#{attribute}"]
          index_document["#{attribute}_tesim"] = resource["#{attribute}"]
        end
      end
    end
  end
end
