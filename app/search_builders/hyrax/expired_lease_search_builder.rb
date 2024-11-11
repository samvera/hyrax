# frozen_string_literal: true
module Hyrax
  # Finds embargoed objects with release dates in the past
  class ExpiredLeaseSearchBuilder < LeaseSearchBuilder
    self.default_processor_chain += [:only_expired_leases]

    def only_expired_leases(solr_params)
      solr_params[:fq] ||= []
      solr_params[:fq] = "lease_expiration_date_dtsi:[* TO #{now}]"
    end

    private

    def now
      Hyrax::TimeService.time_in_utc.utc.xmlschema
    end
  end
end
