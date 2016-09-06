module Sufia
  # Builds a query to find the members of an admin set.
  class AdminSetMemberSearchBuilder < ::SearchBuilder
    self.default_processor_chain += [:in_admin_set]

    # include filters into the query to only include the collection memebers
    def in_admin_set(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "{!term f=isPartOf_ssim}#{blacklight_params.fetch('id')}"
    end
  end
end
