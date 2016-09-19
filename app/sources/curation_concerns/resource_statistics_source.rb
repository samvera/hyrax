module CurationConcerns
  class ResourceStatisticsSource
    attr_accessor :search_builder, :repository
    def initialize(search_builder: ::CatalogController.new.search_builder, repository: ::CatalogController.new.repository)
      # Remove gated discovery.
      @search_builder = search_builder.except(:add_access_controls_to_solr_params)
      @repository = repository
      solr_arguments[:fq] ||= []
      solr_arguments[:rows] = 0
    end

    def open_concerns_count
      results_count("#{Hydra.config.permissions.read.group}:public")
    end

    def authenticated_concerns_count
      results_count("#{Hydra.config.permissions.read.group}:registered")
    end

    def restricted_concerns_count
      # TODO: Replace this with a query that that returns all documents that
      #       either lack the `read_access_group_ssim` key, or have the key
      #       without the values of `public` or `registered`
      repository.search(solr_arguments)["response"]["numFound"] - (authenticated_concerns_count + open_concerns_count)
    end

    def expired_embargo_now_authenticated_concerns_count
      results_count(["#{Hydra.config.permissions.read.group}:registered", "embargo_history_ssim:*"])
    end

    def expired_embargo_now_open_concerns_count
      results_count(["#{Hydra.config.permissions.read.group}:public", "embargo_history_ssim:*"])
    end

    def active_embargo_now_authenticated_concerns_count
      results_count(["#{Hydra.config.permissions.read.group}:registered", "embargo_release_date_dtsi:[NOW TO *]"])
    end

    def active_embargo_now_restricted_concerns_count
      # TODO: Replace the subtraction with another `#where` query that returns
      #       all actively embargoed documents that either lack the
      #       `read_access_group_ssim` key, or have the key without the values
      #       of `public` or `registered`
      all_expired_embargos = results_count("embargo_release_date_dtsi:[NOW TO *]")
      all_expired_embargos - active_embargo_now_authenticated_concerns_count
    end

    def expired_lease_now_authenticated_concerns_count
      results_count(["#{Hydra.config.permissions.read.group}:registered", "lease_history_ssim:*"])
    end

    def expired_lease_now_restricted_concerns_count
      # TODO: Replace the subtraction with another `#where` query that returns
      #       all expired lease documents that either lack the
      #       `read_access_group_ssim` key, or have the key without the values
      #       of `public` or `registered`
      all_leased_documents = results_count("lease_history_ssim:*")
      all_leased_documents - expired_lease_now_authenticated_concerns_count
    end

    def active_lease_now_authenticated_concerns_count
      results_count(["#{Hydra.config.permissions.read.group}:registered", "lease_expiration_date_dtsi:[NOW TO *]"])
    end

    def active_lease_now_open_concerns_count
      results_count(["#{Hydra.config.permissions.read.group}:public", "lease_expiration_date_dtsi:[NOW TO *]"])
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
  end
end
