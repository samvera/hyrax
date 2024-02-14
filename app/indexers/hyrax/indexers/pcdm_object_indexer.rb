# frozen_string_literal: true

module Hyrax
  module Indexers
    ##
    # Indexes non‐fileset PCDM objects
    class PcdmObjectIndexer < Hyrax::Indexers::ResourceIndexer
      include Hyrax::PermissionIndexer
      include Hyrax::VisibilityIndexer
      include Hyrax::LocationIndexer
      include Hyrax::ThumbnailIndexer
      include Hyrax::Indexer(:core_metadata)

      def to_solr # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
        super.tap do |solr_doc|
          solr_doc['generic_type_si'] = 'Work'
          solr_doc['suppressed_bsi'] = suppressed?(resource)
          solr_doc['admin_set_id_ssim'] = [resource.admin_set_id.to_s]
          admin_set_label = admin_set_label(resource)
          solr_doc['admin_set_sim']   = admin_set_label
          solr_doc['admin_set_tesim'] = admin_set_label
          solr_doc["#{Hyrax.config.admin_set_predicate.qname.last}_ssim"] = [resource.admin_set_id.to_s]
          solr_doc['member_of_collection_ids_ssim'] = resource.member_of_collection_ids.map(&:to_s)
          solr_doc['member_ids_ssim'] = resource.member_ids.map(&:to_s)
          solr_doc['depositor_ssim'] = [resource.depositor]
          solr_doc['depositor_tesim'] = [resource.depositor]
          solr_doc['hasRelatedMediaFragment_ssim'] = [resource.representative_id.to_s]
          solr_doc['hasRelatedImage_ssim'] = [resource.thumbnail_id.to_s]
          solr_doc['hasFormat_ssim'] = resource.rendering_ids.map(&:to_s) if resource.rendering_ids.present?
          index_embargo(solr_doc)
          index_lease(solr_doc)
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

      def index_embargo(doc)
        if resource.embargo&.active?
          doc['embargo_release_date_dtsi'] = resource.embargo.embargo_release_date&.to_datetime
          doc['visibility_after_embargo_ssim'] = resource.embargo.visibility_after_embargo
          doc['visibility_during_embargo_ssim'] = resource.embargo.visibility_during_embargo
        else
          doc['embargo_history_ssim'] = resource&.embargo&.embargo_history
        end

        doc
      end

      def index_lease(doc)
        if resource.lease&.active?
          doc['lease_expiration_date_dtsi'] = resource.lease.lease_expiration_date&.to_datetime
          doc['visibility_after_lease_ssim'] = resource.lease.visibility_after_lease
          doc['visibility_during_lease_ssim'] = resource.lease.visibility_during_lease
        else
          doc['lease_history_ssim'] = resource&.lease&.lease_history
        end

        doc
      end
    end
  end
end
