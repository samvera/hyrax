# frozen_string_literal: true

module Hyrax
  module AttributesHelper
    def view_options_for(presenter)
      model_name = presenter.model.model_name.name

      if Hyrax.config.flexible?
        Hyrax::Schema.default_schema_loader.view_definitions_for(schema: model_name, version: presenter.solr_document.schema_version, contexts: presenter.solr_document.contexts)
      else
        schema = model_name.constantize.schema || (model_name + 'Resource').safe_constantize.schema
        Hyrax::Schema.default_schema_loader.view_definitions_for(schema:)
      end
    end

    def conform_field(field_name, options_hash)
      options = HashWithIndifferentAccess.new(options_hash)
      HashWithIndifferentAccess.new(options)['render_term'] || field_name
    end

    # @param [String] field name
    # @param [Hash<Hash>] a nested hash of view options... {:label=>{"en"=>"Title", "es"=>"Título"}, :html_dl=>true}
    def conform_options(field_name, options_hash)
      options = HashWithIndifferentAccess.new(options_hash)
      hash_of_locales = HashWithIndifferentAccess.new(options)['label'] || {}
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
