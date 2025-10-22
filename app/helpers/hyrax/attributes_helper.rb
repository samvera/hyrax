# frozen_string_literal: true

module Hyrax
  module AttributesHelper
    def view_options_for(presenter)
      model_name = presenter.model.model_name.name
      if presenter.respond_to?(:flexible?) && presenter.flexible?
        Hyrax::Schema.m3_schema_loader.view_definitions_for(schema: model_name, version: presenter.solr_document.schema_version, contexts: presenter.solr_document.contexts)
      else
        view_options_without_flexibility(presenter, model_name)
      end
    end

    def view_options_without_flexibility(presenter, model_name)
      model = presenter.model
      schema = schema(model)

      # no schema found for given model - try a few more fallbacks

      # if wings is enabled we may be able to use the model registry to find the new model
      if schema.nil? && !Hyrax.config.disable_wings
        new_model = Wings::ModelRegistry.reverse_lookup(model)
        schema = schema(new_model) if new_model
      end
      # Check if the model has a resource version
      if schema.nil?
        new_model = "#{model_name}Resource".safe_constantize
        schema = schema(new_model) if new_model
      end
      # If we still don't have a schema, assume we have a pre-valkyrie model
      if schema.nil?
        if model.respond_to?(:local_attributes)
          return model.local_attributes
        else
          return []
        end
      end

      Hyrax::Schema.simple_schema_loader.view_definitions_for(schema:)
    end

    # @param [String] model's class name
    # @return [Hash] the schema for the model or nil if not found
    def schema(model)
      return nil unless model.present?

      # If this is an ActiveFedoraDummyModel, get the schema from the actual model class
      if model.is_a?(Hyrax::ActiveFedoraDummyModel)
        actual_model = model.instance_variable_get(:@model)
        return schema(actual_model) if actual_model
      end

      # using respond_to? check because try? does not succeed with Dry::Types object that is returned by schema method
      return nil unless model.respond_to?(:schema)
      model.schema
    end

    # @param [String] field name
    # @param [Hash<Hash>] a nested hash of view options...
    #        {:render_term=>:based_near_label, :label=>{"en"=>"Title", "es"=>"Título"}, :html_dl=>true}
    # @return [String] the field name to be used for rendering
    def conform_field(field_name, options_hash)
      options_hash&.with_indifferent_access&.fetch('render_term', nil) || field_name
    end

    # @param [String] field name
    # @param [Hash<Hash>] a nested hash of view options...
    #        {:label=>{"en"=>"Title", "es"=>"Título"}, :html_dl=>true}
    # @return [Hash] the transformed options for the field
    def conform_options(field_name, view_options)
      hash_of_locales = view_options.delete(:display_label) || {}

      if hash_of_locales.present?
        view_options[:label] = hash_of_locales[locale] || hash_of_locales[:default]
      else
        view_options[:label] = (view_options[:render_term] || field_name).to_s.humanize
      end
      view_options[:label] = t(view_options[:label], default: view_options[:label])
      view_options
    end
  end
end
