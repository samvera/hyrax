module Hyrax
  # Returns all works, either active or suppressed.
  # This should only be used by an admin user
  class WorksSearchBuilder < ::SearchBuilder
    self.default_processor_chain -= [:only_active_works]

    def by_depositor(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "{!field f=#{DepositSearchBuilder.depositor_field} v=#{blacklight_params[:depositor]}}" if blacklight_params[:depositor].present?
    end

    private

      def only_works?
        true
      end
  end
end
