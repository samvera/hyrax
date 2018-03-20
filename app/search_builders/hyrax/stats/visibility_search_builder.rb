module Hyrax
  module Stats
    class VisibilitySearchBuilder < ::SearchBuilder
      self.default_processor_chain = [:include_resource_type_facet, :filter_models]

      # use caution when combining this with other searches as it sets the rows to
      # zero to just get the facet information
      # @param solr_parameters the current solr parameters
      def include_resource_type_facet(solr_parameters)
        solr_parameters[:"facet.field"].concat(["visibility_ssi"])
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