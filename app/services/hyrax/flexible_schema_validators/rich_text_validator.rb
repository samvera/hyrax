# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    # Warns when a property is declared with `form: { input_type: rich_text }`
    # but is also configured as a controlled value. A rich-text field stores
    # free-form HTML, which is incompatible with a curated/authority value, and
    # the rich-text editor pre-empts the controlled widget at the single
    # edit-field render entry point, so the dropdown/autocomplete is silently
    # dropped. `rich_text` is meant only for free-text string properties.
    #
    # Flexible mode has no single declarative "controlled" flag, so this keys on
    # what the profile declares (or what Hyrax/Hyku render by convention):
    #   * a real `controlled_values.sources` entry, i.e. a local or remote
    #     authority - anything other than the `"null"` free-text sentinel
    #     (Hyku renders these as a select or autocomplete), or
    #   * a built-in property rendered with a controlled widget by field-name
    #     convention regardless of declared sources (dedicated edit-field
    #     partials / authority services), or
    #   * a compound subproperty declared `type: controlled`.
    class RichTextValidator
      # Built-in properties Hyrax renders with a controlled widget by field-name
      # convention, even when their profile entry leaves
      # `controlled_values.sources` as the `"null"` sentinel.
      CONTROLLED_BY_CONVENTION = %w[
        rights_statement license resource_type based_near language access_right
      ].freeze

      def initialize(profile, warnings)
        @profile = profile
        @warnings = warnings
      end

      def validate!
        (@profile['properties'] || {}).each do |name, config|
          next unless config.is_a?(Hash) && rich_text?(config)

          key, options = conflict_for(name, config)
          next unless key

          @warnings << I18n.t("hyrax.flexible_schema_validators.rich_text_validator.warnings.#{key}", **options)
        end
      end

      private

      def rich_text?(config)
        config.dig('form', 'input_type').to_s == 'rich_text'
      end

      # @return [Array(Symbol, Hash), nil] the i18n warning key and its
      #   interpolation options, or nil when the property is free-text (a valid
      #   target for rich_text).
      def conflict_for(name, config)
        sources = real_sources(config)
        if sources.present?
          [:controlled_sources, { property: name, sources: sources.join(', ') }]
        elsif CONTROLLED_BY_CONVENTION.include?(name.to_s)
          [:built_in, { property: name }]
        elsif config['type'].to_s == 'controlled'
          [:controlled_type, { property: name }]
        end
      end

      # Controlled-vocabulary sources, excluding the `"null"` sentinel (and
      # blanks) the profile uses to mean "free text / no authority".
      def real_sources(config)
        Array(config.dig('controlled_values', 'sources')).reject do |source|
          value = source.to_s.strip
          value.empty? || value.casecmp('null').zero?
        end
      end
    end
  end
end
