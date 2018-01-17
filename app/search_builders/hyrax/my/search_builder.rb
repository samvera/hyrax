module Hyrax
  module My
    # Search builder for things that the current user has deposited and has edit access to
    # @abstract
    class SearchBuilder < ::SearchBuilder
      # Check for edit access
      include Hyrax::My::SearchBuilderBehavior
      self.default_processor_chain += [:show_only_resources_deposited_by_current_user]

      # adds a filter to the solr_parameters that filters the documents the current user
      # has deposited
      # @param [Hash] solr_parameters
      def show_only_resources_deposited_by_current_user(solr_parameters)
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] += [
          "_query_:\"{!raw f=depositor_ssim}#{current_user_key}\""
        ]
      end
    end
  end
end
