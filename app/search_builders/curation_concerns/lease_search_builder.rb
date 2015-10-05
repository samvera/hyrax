module CurationConcerns
  # Finds objects under lease
  class LeaseSearchBuilder < Blacklight::SearchBuilder
    self.default_processor_chain = [:add_paging_to_solr, :only_active_leases]
    def initialize(scope)
      super(true, scope)
    end

    # TODO: add more complex pagination
    def add_paging_to_solr(solr_params)
      solr_params[:rows] = 1000
    end

    def only_active_leases(solr_params)
      solr_params[:fq] ||= []
      solr_params[:fq] = 'lease_expiration_date_dtsi:*'
    end
  end
end
