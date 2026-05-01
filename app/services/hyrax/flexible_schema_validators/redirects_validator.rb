# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    ##
    # @api private
    #
    # Validates the `redirects` property in an m3 profile against the
    # two-layer feature gating (config + Flipflop):
    #
    # | config | flipflop | property | result                              |
    # |--------|----------|----------|-------------------------------------|
    # | off    | n/a      | present  | warn (property will be ignored)     |
    # | off    | n/a      | absent   | silent                              |
    # | on     | off      | present  | warn (property is loaded but unused)|
    # | on     | off      | absent   | silent                              |
    # | on     | on       | absent   | error (property is required)        |
    # | on     | on       | present  | check available_on.class and pass   |
    # |        |          |          | or error if work/collection missing |
    class RedirectsValidator
      REQUIRED_CLASSES = %w[Hyrax::Work Hyrax::PcdmCollection].freeze

      ##
      # @param profile [Hash] the flexible metadata profile
      # @param errors [Array<String>] an array to append errors to
      # @param warnings [Array<String>] an array to append warnings to
      def initialize(profile:, errors:, warnings: [])
        @profile = profile
        @errors = errors
        @warnings = warnings
      end

      # Validate the profile against the redirects requirements and append
      # any human-readable error messages to {#errors} (or warnings to
      # {#warnings} for the dead-property cases).
      #
      # @return [void]
      def validate!
        return validate_when_config_off unless Hyrax.config.redirects_enabled?
        return validate_when_flipflop_off unless Flipflop.redirects?

        validate_when_enabled
      end

      private

      def redirects_property
        @redirects_property ||= @profile&.dig('properties', 'redirects')
      end

      def validate_when_config_off
        return if redirects_property.blank?
        warn_dead_property('Hyrax.config.redirects_enabled? is false')
      end

      def validate_when_flipflop_off
        return if redirects_property.blank?
        warn_dead_property('the :redirects feature flag is off for this tenant')
      end

      def validate_when_enabled
        if redirects_property.blank?
          @errors << 'm3 profile must declare a `redirects` property when the redirects feature is enabled'
          return
        end

        available_on = Array(redirects_property.dig('available_on', 'class'))
        missing = REQUIRED_CLASSES - available_on
        return if missing.empty?

        @errors << "m3 profile `redirects` property must be available on: #{missing.join(', ')}"
      end

      def warn_dead_property(reason)
        @warnings << "m3 profile declares a `redirects` property but #{reason}; " \
                     'the property will be ignored'
      end
    end
  end
end
