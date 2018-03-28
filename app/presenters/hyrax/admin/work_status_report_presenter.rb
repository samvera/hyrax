module Hyrax
  module Admin
    class WorkStatusReportPresenter
      attr_reader :limit, :stats_filters

      def initialize(stats_filters, limit)
        @stats_filters = stats_filters
        @limit = limit
      end

      def current_work_types
        results = ActiveFedora::SolrService.instance.conn.get(
          ActiveFedora::SolrService.select_path,
          params: { fq: '{!terms f=generic_type_sim}Work',
                    'facet.field' => 'has_model_ssim' }
        )
        results['facet_counts']['facet_fields']['has_model_ssim'].select { |t| t.is_a? String } || []
      end

      def available_work_types
        Hyrax.config.curation_concerns.map(&:to_s)
      end

      def work_count
        Hyrax::Statistics::Works::Count.by_permission[:total]
      end

      def statuses
        Sipity::WorkflowState.all.to_a.map(&:name).uniq.sort
      end

      def visibilities
        [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
         Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
         Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO,
         Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE,
         Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE]
      end

      def sort_by
        []
      end

      def user_count
        Hyrax::Admin::UsersPresenter.new.user_count
      end
    end
  end
end
