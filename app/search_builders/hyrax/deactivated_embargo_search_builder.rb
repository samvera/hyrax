# frozen_string_literal: true
module Hyrax
  class DeactivatedEmbargoSearchBuilder < EmbargoSearchBuilder
    self.default_processor_chain += [:with_deactivated_embargos]

    def with_deactivated_embargos(solr_params)
      solr_params[:fq] ||= []
      solr_params[:fq] = 'embargo_history_ssim:*'
    end
  end
end
