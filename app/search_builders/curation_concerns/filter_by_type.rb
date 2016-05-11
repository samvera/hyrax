module CurationConcerns
  module FilterByType
    extend ActiveSupport::Concern

    included do
      self.default_processor_chain += [:filter_models]
    end

    # Add queries that excludes everything except for works and collections
    def filter_models(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << '(' + (work_clauses + collection_clauses).join(' OR ') + ')'
    end

    private

      # Override this method if you want to limit some of the registered
      # types from appearing in search results
      # @returns [Array<Class>] the list of work types to include in searches
      def work_types
        CurationConcerns.config.curation_concerns
      end

      def work_clauses
        return [] if blacklight_params.key?(:f) && Array.wrap(blacklight_params[:f][:generic_type_sim]).include?('Collection')
        work_types.map do |klass|
          ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: klass.to_class_uri)
        end
      end

      def collection_clauses
        return [] if blacklight_params.key?(:f) && Array.wrap(blacklight_params[:f][:generic_type_sim]).include?('Work')
        [ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: ::Collection.to_class_uri)]
      end
  end
end
