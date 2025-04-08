# frozen_string_literal: true

module Hyrax
  module AttributesHelper
    def view_options_for(presenter)
      model_name = presenter.model.model_name.name

      if Hyrax.config.flexible?
        Hyrax::Schema.default_schema_loader.view_definitions_for(schema: model_name, version: presenter.solr_document.schema_version, contexts: presenter.solr_document.contexts)
      else
        view_options_without_flexibility(model_name)
      end
    end

    def view_options_without_flexibility(model_name)
      model = model_name.safe_constantize
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

      Hyrax::Schema.default_schema_loader.view_definitions_for(schema:)
    end

    # @param [String] model's class name
    # @return [Hash] the schema for the model or nil if not found
    def schema(model)
      return nil unless model.present?
      # using respond_to? check because try? does not succeed with Dry::Types object that is returned by schema method
      return nil unless model.respond_to?(:schema)
      model.schema
    end

    # @param [String] field name
    # @param [Hash<Hash>] a nested hash of view options...
    #        {:render_term=>:based_near_label, :label=>{"en"=>"Title", "es"=>"Título"}, :html_dl=>true}
    # @return [String] the field name to be used for rendering
    def conform_field(field_name, options_hash)
      options = HashWithIndifferentAccess.new(options_hash)
      HashWithIndifferentAccess.new(options)['render_term'] || field_name
    end

    # @param [String] field name
    # @param [Hash<Hash>] a nested hash of view options...
    #        {:label=>{"en"=>"Title", "es"=>"Título"}, :html_dl=>true}
    # @return [Hash] the transformed options for the field
    def conform_options(field_name, options_hash)
      options = HashWithIndifferentAccess.new(options_hash)
      options_hash = HashWithIndifferentAccess.new(options)
      hash_of_locales = options_hash['render_term'] || options_hash['label'] || {}
      current_locale = params['locale'] || I18n.locale.to_s

      unless hash_of_locales.present?
        options[:label] = field_name.to_s.humanize
        return options
      end

      return options_hash if hash_of_locales.is_a?(String) || hash_of_locales.empty?

      # If the params locale is found in the hash of locales, use that value
      if hash_of_locales[current_locale].present?
        options[:label] = hash_of_locales[current_locale]
      # If the params locale is not found, fall back to english
      elsif hash_of_locales['en']
        options[:label] = hash_of_locales['en']
      # If the params locale is not found and english is not found, use the first value in the hash as a fallback
      elsif hash_of_locales['en'].nil? && hash_of_locales[current_locale].nil?
        options[:label] = hash_of_locales.values.first
      end

      options
    end
  end
end
