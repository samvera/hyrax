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
        solr_doc['generic_type_si'] = 'Work'
        solr_doc['suppressed_bsi'] = suppressed?(resource)
        solr_doc['admin_set_id_ssim'] = [resource.admin_set_id.to_s]
        admin_set_label = admin_set_label(resource)
        solr_doc['admin_set_sim']   = admin_set_label
        solr_doc['admin_set_tesim'] = admin_set_label
        solr_doc['member_of_collection_ids_ssim'] = resource.member_of_collection_ids.map(&:to_s)
        solr_doc['member_ids_ssim'] = resource.member_ids.map(&:to_s)
        solr_doc['depositor_ssim'] = [resource.depositor]
        solr_doc['depositor_tesim'] = [resource.depositor]
      end
    end

    private

    def suppressed?(resource)
      Hyrax::ResourceStatus.new(resource: resource).inactive?
    end

    def admin_set_label(resource)
      return if resource.admin_set_id.blank?
      admin_set = Hyrax.query_service.find_by(id: resource.admin_set_id)
      admin_set.title
    end
  end
end
