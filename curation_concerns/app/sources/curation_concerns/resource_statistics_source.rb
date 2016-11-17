module CurationConcerns
  class ResourceStatisticsSource
    attr_accessor :search_builder, :repository
    def initialize(search_builder: ::CurationConcerns::AdminController.new.search_builder, repository: ::CurationConcerns::AdminController.new.repository)
      # Remove gated discovery.
      @search_builder = search_builder.except(:add_access_controls_to_solr_params)
      @repository = repository
      solr_arguments[:fq] ||= []
      solr_arguments[:rows] = 0
    end

    def open_concerns_count
      results_count(public_read_group)
    end

    def authenticated_concerns_count
      results_count(registered_read_group)
    end

    def restricted_concerns_count
      results_count([not_registered_read_group, not_public_read_group])
    end

    def expired_embargo_now_authenticated_concerns_count
      results_count([registered_read_group, embargo_history_query])
    end

    def expired_embargo_now_open_concerns_count
      results_count([public_read_group, embargo_history_query])
    end

    def active_embargo_now_authenticated_concerns_count
      results_count([registered_read_group, active_embargo])
    end

    def active_embargo_now_restricted_concerns_count
      results_count([not_registered_read_group, not_public_read_group, active_embargo])
    end

    def expired_lease_now_authenticated_concerns_count
      results_count([registered_read_group, lease_history_query])
    end

    def expired_lease_now_restricted_concerns_count
      results_count([not_registered_read_group, not_public_read_group, lease_history_query])
    end

    def active_lease_now_authenticated_concerns_count
      results_count([registered_read_group, active_lease])
    end

    def active_lease_now_open_concerns_count
      results_count([public_read_group, active_lease])
    end

    private

      def solr_arguments
        @solr_arguments ||= search_builder.to_h
      end

      def results_count(query)
        q = { fq: Array.wrap(query) }
        repository.search(solr_arguments.merge(q) do |_key, v1, v2|
          v1 + v2
        end)["response"]["numFound"]
      end

      def active_lease
        "lease_expiration_date_dtsi:[NOW TO *]"
      end

      def active_embargo
        "embargo_release_date_dtsi:[NOW TO *]"
      end

      def lease_history_query
        "lease_history_ssim:*"
      end

      def embargo_history_query
        "embargo_history_ssim:*"
      end

      def registered_read_group
        "#{Hydra.config.permissions.read.group}:registered"
      end

      def not_registered_read_group
        "-#{registered_read_group}"
      end

      def public_read_group
        "#{Hydra.config.permissions.read.group}:public"
      end

      def not_public_read_group
        "-#{public_read_group}"
      end
  end
end
