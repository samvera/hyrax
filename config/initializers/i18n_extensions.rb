# frozen_string_literal: true

# Extensions to the I18n module to enable reverse lookup of translation keys by their values
# This is useful for debugging, testing, and finding where specific text comes from in the codebase
module I18n
  class << self
    # Find translation key(s) that have a specific value
    # @param value [String] The translation value to search for
    # @param locale [Symbol] The locale to search in (defaults to current locale)
    # @param scope [String, Symbol, Array] Optional scope to limit search
    # @param exact [Boolean] Whether to match exactly or use partial matching (default: true)
    # @return [Array<String>] Array of matching key paths
    def find_keys_by_value(value, locale: I18n.locale, scope: nil, exact: true)
      results = []
      translations = backend.translations[locale] || {}

      # Navigate to scope if provided
      if scope
        scope_parts = Array(scope).map(&:to_s)
        scope_parts.each do |part|
          translations = translations[part.to_sym] || translations[part.to_s]
          return [] unless translations
        end
      end

      search_nested_translations(translations, value, [], results, exact, scope)
      results
    end

    # Find the first translation key that matches a value
    # @param value [String] The translation value to search for
    # @param locale [Symbol] The locale to search in
    # @param scope [String, Symbol, Array] Optional scope to limit search
    # @return [String, nil] The first matching key path or nil
    def reverse_lookup(value, locale: I18n.locale, scope: nil)
      find_keys_by_value(value, locale: locale, scope: scope, exact: true).first
    end

    # Find all translation keys containing a value (partial match)
    # @param value [String] The translation value to search for
    # @param locale [Symbol] The locale to search in
    # @param scope [String, Symbol, Array] Optional scope to limit search
    # @return [Array<String>] Array of matching key paths
    def find_keys_containing(value, locale: I18n.locale, scope: nil)
      find_keys_by_value(value, locale: locale, scope: scope, exact: false)
    end

    # Get all translation keys for a given locale
    # @param locale [Symbol] The locale to get keys for
    # @param scope [String, Symbol, Array] Optional scope to limit results
    # @return [Array<String>] Array of all translation keys
    def all_keys(locale: I18n.locale, scope: nil)
      translations = backend.translations[locale] || {}

      # Navigate to scope if provided
      if scope
        scope_parts = Array(scope).map(&:to_s)
        scope_parts.each do |part|
          translations = translations[part.to_sym] || translations[part.to_s]
          return [] unless translations
        end
      end

      keys = []
      collect_keys(translations, [], keys, scope)
      keys
    end

    # Get translation value and its metadata
    # @param key [String, Symbol] The translation key
    # @param locale [Symbol] The locale to search in
    # @return [Hash] Hash containing value, key, locale, and full path
    def lookup_with_info(key, locale: I18n.locale, **options)
      value = I18n.t(key, locale: locale, **options)

      {
        key: key.to_s,
        value: value,
        locale: locale,
        exists: !value.to_s.start_with?('translation missing:'),
        default: options[:default],
        scope: options[:scope]
      }
    end

    private

    def search_nested_translations(hash, target_value, current_path, results, exact, scope_prefix) # rubocop:disable Metrics/ParameterLists, Metrics/MethodLength
      hash.each do |key, value|
        path = current_path + [key]

        if value.is_a?(Hash)
          search_nested_translations(value, target_value, path, results, exact, scope_prefix)
        elsif value.is_a?(Array)
          # Handle array translations (like error messages with multiple items)
          value.each_with_index do |item, index|
            if match_value?(item, target_value, exact)
              full_path = build_key_path(path + [index], scope_prefix)
              results << full_path
            end
          end
        elsif match_value?(value, target_value, exact)
          full_path = build_key_path(path, scope_prefix)
          results << full_path
        end
      end
    end

    def match_value?(value, target_value, exact)
      value_str = value.to_s
      target_str = target_value.to_s

      if exact
        value_str == target_str
      else
        value_str.downcase.include?(target_str.downcase)
      end
    end

    def build_key_path(path, scope_prefix)
      key_path = path.map(&:to_s).join('.')
      if scope_prefix
        scope_str = Array(scope_prefix).map(&:to_s).join('.')
        "#{scope_str}.#{key_path}"
      else
        key_path
      end
    end

    def collect_keys(hash, current_path, keys, scope_prefix)
      hash.each do |key, value|
        path = current_path + [key]

        if value.is_a?(Hash)
          collect_keys(value, path, keys, scope_prefix)
        else
          full_path = build_key_path(path, scope_prefix)
          keys << full_path
        end
      end
    end
  end
end

# Convenience module for inclusion in classes
module I18nReverseLookup
  extend ActiveSupport::Concern

  # Instance methods
  def find_translation_key(value, options = {})
    I18n.reverse_lookup(value, **options)
  end

  def find_all_translation_keys(value, options = {})
    I18n.find_keys_by_value(value, **options)
  end

  # Class methods
  class_methods do
    def find_translation_key(value, options = {})
      I18n.reverse_lookup(value, **options)
    end

    def find_all_translation_keys(value, options = {})
      I18n.find_keys_by_value(value, **options)
    end
  end
end

# Add Rails-specific helpers if Rails is defined
if defined?(Rails)
  module I18nRailsExtensions
    # Debug helper to show where a translation comes from
    def translation_debug(key, options = {})
      result = I18n.lookup_with_info(key, **options)

      Rails.logger.debug "I18n Debug: #{result.inspect}" if defined?(Rails.logger) && Rails.logger

      result
    end

    # Find translations in view paths
    def find_in_views(value, exact: false)
      results = []

      # Search in all loaded locales
      I18n.available_locales.each do |locale|
        keys = I18n.find_keys_by_value(value, locale: locale, exact: exact)
        results.concat(keys.map { |k| { locale: locale, key: k } })
      end

      results
    end
  end

  I18n.extend(I18nRailsExtensions)
end
