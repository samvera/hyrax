# frozen_string_literal: true

module Hyrax
  ##
  # Indexes Hyrax::Work objects
  class ValkyrieWorkIndexer < Hyrax::ValkyrieIndexer
    include Hyrax::ResourceIndexer
    include Hyrax::PermissionIndexer
    include Hyrax::VisibilityIndexer
    include Hyrax::Indexer(:core_metadata)

    def to_solr # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      super.tap do |solr_doc|
        solr_doc['generic_type_sim'] = ['Work']
        solr_doc['suppressed_bsi'] = suppressed?(resource)
        solr_doc['admin_set_id_ssim'] = [resource.admin_set_id.to_s]
        solr_doc['member_of_collection_ids_ssim'] = resource.member_of_collection_ids.map(&:to_s)
        solr_doc['member_ids_ssim'] = resource.member_ids.map(&:to_s)
      end
    end

    private

    def suppressed?(resource)
      Hyrax::ResourceStatus.new(resource: resource).inactive?
    end
  end
end
