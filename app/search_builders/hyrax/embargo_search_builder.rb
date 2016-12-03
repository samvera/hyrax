module Hyrax
  # Finds embargoed objects
  class EmbargoSearchBuilder < Blacklight::SearchBuilder
    self.default_processor_chain = [:with_pagination, :with_sorting, :only_active_embargoes]

    # TODO: add more complex pagination
    def with_pagination(solr_params)
      solr_params[:rows] = 1000
    end

    def with_sorting(solr_params)
      solr_params[:sort] = 'embargo_release_date_dtsi desc'
    end

    def only_active_embargoes(solr_params)
      solr_params[:fq] ||= []
      solr_params[:fq] = 'embargo_release_date_dtsi:*'
    end
  end
end
