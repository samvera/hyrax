module Hyrax
  module My
    # Search builder for things that the current user has deposited
    # @abstract
    class SearchBuilder < ::SearchBuilder
      include Hyrax::My::SearchBuilderBehavior
      self.default_processor_chain += [:show_only_resources_deposited_by_current_user]

      # adds a filter to the solr_parameters that filters the documents the current user
      # has deposited
      # @param [Hash] solr_parameters
      def show_only_resources_deposited_by_current_user(solr_parameters)
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] += [
          ActiveFedora::SolrQueryBuilder.construct_query_for_rel(depositor: current_user_key)
        ]
      end
    end
  end
end
