# frozen_string_literal: true

module Hyrax
  module AttributesHelper
    def view_options_for(presenter)
      model_name = presenter.model.model_name.name.constantize
      hash = Hyrax::Schema.schema_to_hash_for(model_name) ||
             Hyrax::Schema.schema_to_hash_for((model_name.to_s + 'Resource').safe_constantize)

      hash.select { |_, val| val['view'].present? }
    end

    def conform_options(options)
      hash_of_locales = options.dig('view', 'label') || {}
      current_locale = params['locale'] || I18n.locale.to_s
      updated_options = options.deep_dup

      return updated_options['view'].transform_keys(&:to_sym) if hash_of_locales.is_a?(String)

      label =
        # params locale is found in the hash of locales, use that value
        if hash_of_locales[current_locale].present?
          hash_of_locales[current_locale]
        # params locale is not found, fall back to English
        elsif hash_of_locales['en']
          hash_of_locales['en']
        # params locale is not found and English is not found, use the first value in the hash as the fallback
        elsif hash_of_locales.present?
          hash_of_locales.values.first
        end

      updated_options['view']['label'] = label if label

      updated_options['view'].transform_keys(&:to_sym)
    end
  end
end
