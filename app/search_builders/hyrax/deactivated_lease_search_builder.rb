# frozen_string_literal: true
module Hyrax
  class DeactivatedLeaseSearchBuilder < LeaseSearchBuilder
    self.default_processor_chain += [:with_deactivated_leases]

    def with_deactivated_leases(solr_params)
      solr_params[:fq] ||= []
      solr_params[:fq] = 'lease_history_ssim:*'
    end
  end
end
