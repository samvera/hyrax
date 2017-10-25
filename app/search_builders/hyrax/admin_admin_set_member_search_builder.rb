module Hyrax
  # Builds a query to find the members of an admin set.
  # For use on the admin menu, so it includes works regardless of status.
  class AdminAdminSetMemberSearchBuilder < ::SearchBuilder
    self.default_processor_chain += [:in_admin_set]
    self.default_processor_chain -= [:only_active_works]

    attr_reader :collection

    # @param [scope] Typically the controller object
    # @param [Collection]
    def initialize(scope:, collection:)
      @collection = collection
      super(scope)
    end

    # include filters into the query to only include the admin_set members (regardless of status)
    def in_admin_set(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "{!term f=isPartOf_ssim}#{collection.id}"
    end
  end
end
