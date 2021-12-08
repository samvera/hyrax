# frozen_string_literal: true
module Hyrax
  module Stats
    class WorkStatusSearchBuilder < ::SearchBuilder
      self.default_processor_chain = [:include_suppressed_facet, :filter_models]

      # includes the suppressed facet to get information on deposits.
      # use caution when combining this with other searches as it sets the rows to
      # zero to just get the facet information
      # @param solr_parameters the current solr parameters
      def include_suppressed_facet(solr_parameters)
        solr_parameters[:"facet.field"] = solr_parameters.fetch(:"facet.field", []).concat([IndexesWorkflow.suppressed_field])
        solr_parameters[:'facet.missing'] = true

        # we only want the facet counts not the actual data
        solr_parameters[:rows] = 0
      end

      private

      def only_works?
        true
      end
    end
  end
end
