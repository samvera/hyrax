# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    # Warns about a compound `validations:` rule that will never fire.
    #
    # {Hyrax::CompoundSchema} normalizes the rule's shape without checking its
    # `type`, so an unrecognized one is stored and then quietly ignored at
    # validation time. That keeps a profile written against a newer Hyrax loadable
    # here, but it also means a misspelling (`ordred`) silently disables the rule.
    # Warning rather than erroring preserves the first while surfacing the second.
    class CompoundValidationsValidator
      def initialize(profile, warnings)
        @profile = profile
        @warnings = warnings
      end

      def validate!
        (@profile['properties'] || {}).each do |name, config|
          next unless config.is_a?(Hash)

          rules(config).each { |rule| warn_about(name, rule) }
        end
      end

      private

      def rules(config)
        value = config['validations']
        value.is_a?(Array) ? value.select { |rule| rule.is_a?(Hash) } : []
      end

      def warn_about(compound, rule)
        type = rule['type'].to_s

        if Hyrax::CompoundEntryValidation::RULE_TYPES.exclude?(type)
          add(:unknown_type, compound: compound, type: type.presence || '(blank)')
        elsif rule['before'].blank? || rule['after'].blank?
          add(:incomplete_rule, compound: compound, type: type)
        end
      end

      def add(key, **options)
        @warnings << I18n.t("hyrax.flexible_schema_validators.compound_validations_validator.warnings.#{key}",
                            **options)
      end
    end
  end
end
