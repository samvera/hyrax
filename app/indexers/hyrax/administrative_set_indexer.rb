# frozen_string_literal: true

module Hyrax
  ##
  # Indexes Hyrax::AdministrativeSet objects
  class AdministrativeSetIndexer < Hyrax::ValkyrieIndexer
    include Hyrax::ResourceIndexer
    include Hyrax::PermissionIndexer
    include Hyrax::VisibilityIndexer
    include Hyrax::Indexer(:core_metadata)

    def to_solr # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      super.tap do |solr_doc|
        solr_doc[:alternative_title_tesim] = resource.alternative_title
        solr_doc[:creator_ssim]            = [resource.creator]
        solr_doc[:creator_tesim]           = [resource.creator]
        solr_doc[:description_tesim]       = resource.description
        solr_doc[:generic_type_sim]        = ['Admin Set']
        solr_doc[:thumbnail_path_ss]       = Hyrax::CollectionThumbnailPathService.call(resource)
      end
    end
  end
end
