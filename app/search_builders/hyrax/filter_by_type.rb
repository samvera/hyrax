# frozen_string_literal: true
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

    private

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

    def models_to_solr_clause
      models.map do |model|
        model.respond_to?(:to_rdf_representation) ? model.to_rdf_representation : model.name
      end.join(',')
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
      [::Collection, Hyrax::PcdmCollection]
    end
  end
end
