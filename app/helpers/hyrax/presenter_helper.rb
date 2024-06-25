# frozen_string_literal: true

module Hyrax
  module PresenterHelper
    def view_options_for(presenter)
      model_name = presenter.model.model_name.name.constantize
      hash = Hyrax::Schema.schema_to_hash_for(model_name) ||
               Hyrax::Schema.schema_to_hash_for((model_name.to_s + 'Resource').safe_constantize)

      hash.select { |_, val| val['view'].present? }
    end

    def conform_options(options)
      hash_of_locales = options['view']['label']
      current_locale = params['locale'] || I18n.locale.to_s
      
      # Check if hash_of_locales is a hash and contains the current locale
      if hash_of_locales.is_a?(Hash) && hash_of_locales[current_locale].present?
        # Create a copy of options to avoid modifying the original hash during iteration
        updated_options = options.deep_dup
        
        # Update the label based on the current locale
        updated_options['view']['label'] = hash_of_locales[current_locale]
        
        # Transform keys to symbols and return the modified options
        return updated_options['view'].transform_keys(&:to_sym)
      end
    
      # If label is not a hash or does not contain the locale, transform keys to symbols as usual
      options['view'].transform_keys(&:to_sym)
    end
  end
end
