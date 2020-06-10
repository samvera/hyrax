# frozen_string_literal: true
module Hyrax
  module Dashboard
    class WorksSearchBuilder < Hyrax::WorksSearchBuilder
      include Hyrax::Dashboard::ManagedSearchFilters

      self.default_processor_chain += [:show_only_managed_works_for_non_admins]

      # Adds a filter to exclude works created by the current user if the
      # current user is not an admin.
      # @param [Hash] solr_parameters
      def show_only_managed_works_for_non_admins(solr_parameters)
        return if current_ability.admin?
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] << '-' + ActiveFedora::SolrQueryBuilder.construct_query_for_rel(depositor: current_user_key)
      end
    end
  end
end
