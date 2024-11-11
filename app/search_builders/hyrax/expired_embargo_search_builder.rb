# frozen_string_literal: true
module Hyrax
  # Finds embargoed objects with release dates in the past
  class ExpiredEmbargoSearchBuilder < EmbargoSearchBuilder
    self.default_processor_chain += [:only_expired_embargoes]

    def only_expired_embargoes(solr_params)
      solr_params[:fq] ||= []
      solr_params[:fq] = "embargo_release_date_dtsi:[* TO #{now}]"
    end

    private

    def now
      Hyrax::TimeService.time_in_utc.utc.xmlschema
    end
  end
end
