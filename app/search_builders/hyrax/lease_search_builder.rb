module Hyrax
  # Finds objects under lease
  class LeaseSearchBuilder < Blacklight::SearchBuilder
    self.default_processor_chain = [:with_pagination, :with_sorting, :only_active_leases]

    # TODO: add more complex pagination
    def with_pagination(solr_params)
      solr_params[:rows] = 1000
    end

    def with_sorting(solr_params)
      solr_params[:sort] = 'lease_expiration_date_dtsi desc'
    end

    def only_active_leases(solr_params)
      solr_params[:fq] ||= []
      solr_params[:fq] = 'lease_expiration_date_dtsi:*'
    end
  end
end
