module CurationConcerns
  module FilterByType
    extend ActiveSupport::Concern

    included do
      self.default_processor_chain += [:filter_models]
    end

    # Add queries that excludes everything except for works and collections
    def filter_models(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << '{!terms f=has_model_ssim}' + (work_clauses + collection_clauses).join(',')
    end

    protected

      def only_collections?
        generic_type_field.include?('Collection')
      end

      def only_works?
        generic_type_field.include?('Work')
      end

    private

      def generic_type_field
        Array.wrap(blacklight_params.fetch(:f, {}).fetch(:generic_type_sim, []))
      end

      # Override this method if you want to limit some of the registered
      # types from appearing in search results
      # @returns [Array<Class>] the list of work types to include in searches
      def work_types
        CurationConcerns.config.curation_concerns
      end

      def work_clauses
        return [] if only_collections?
        work_types.map(&:to_class_uri)
      end

      def collection_clauses
        return [] if only_works?
        [::Collection.to_class_uri]
      end
  end
end
