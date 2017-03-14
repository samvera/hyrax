module Hyrax
  module FilterByType
    extend ActiveSupport::Concern

    included do
      self.default_processor_chain += [:filter_models]
    end

    # Add queries that excludes everything except for works and collections
    def filter_models(solr_parameters)
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "{!terms f=has_model_ssim}#{models_to_solr_clause}"
    end

    protected

      def only_collections?
        generic_type_field.include?('Collection')
      end

      def only_works?
        generic_type_field.include?('Work')
      end

      # Override this method if you want to filter for a different set of models.
      # @return [Array<Class>] a list of classes to include
      def models
        work_classes + collection_classes
      end

    private

      def models_to_solr_clause
        # to_class_uri is deprecated in AF 11
        [ActiveFedora::Base.respond_to?(:to_rdf_representation) ? models.map(&:to_rdf_representation) : models.map(&:to_class_uri)].join(',')
      end

      def generic_type_field
        Array.wrap(blacklight_params.fetch(:f, {}).fetch(:generic_type_sim, []))
      end

      # Override this method if you want to limit some of the registered
      # types from appearing in search results
      # @return [Array<Class>] the list of work types to include in searches
      def work_types
        Hyrax.config.curation_concerns
      end

      def work_classes
        return [] if only_collections?
        work_types
      end

      def collection_classes
        return [] if only_works?
        # to_class_uri is deprecated in AF 11
        [::Collection]
      end
  end
end
