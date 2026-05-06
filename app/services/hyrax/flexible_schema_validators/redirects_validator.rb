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
    # | on     | on       | present  | check available_on.class lists at   |
    # |        |          |          | least one work or collection class  |
    # |        |          |          | declared in this profile's classes  |
    class RedirectsValidator
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

        @errors << "m3 profile `redirects` property must declare `type: hash` (got `#{redirects_property['type'].inspect}`)" unless redirects_property['type'].to_s == 'hash'

        available_on = clean(Array(redirects_property.dig('available_on', 'class')))
        return if (available_on & profile_work_or_collection_classes).any?

        @errors << 'm3 profile `redirects` property must be available on at least one work or collection class declared in this profile'
      end

      # Class names declared in this m3 profile's top-level `classes:` block,
      # filtered to keep only those that represent works or collections.
      # FileSets, AdminSets, and any non-work/non-collection class are
      # excluded — redirects only apply to works and collections.
      def profile_work_or_collection_classes
        @profile_work_or_collection_classes ||= begin
          declared = clean(Array(@profile&.dig('classes')&.keys))
          declared.select { |name| work_or_collection?(name) }
        end
      end

      def work_or_collection?(class_name)
        registered_collection_names.include?(class_name) ||
          registered_work_names.include?(class_name)
      end

      def registered_collection_names
        @registered_collection_names ||= clean(Hyrax::ModelRegistry.collection_class_names)
      end

      # Work class names from the registry, with collection / file_set /
      # admin_set names explicitly excluded. The registry can include any
      # class an adopter has registered as a curation concern, so the
      # exclusion guards against e.g. a FileSet being registered alongside
      # works and slipping through as a "work" type for redirects.
      # Each registered name is also paired with its `Resource`-suffixed
      # Valkyrie equivalent — `class_validator` accepts both forms.
      def registered_work_names
        @registered_work_names ||= begin
          works = clean(Hyrax::ModelRegistry.work_class_names)
          works -= clean(Hyrax::ModelRegistry.collection_class_names)
          works -= clean(Hyrax::ModelRegistry.file_set_class_names)
          works -= clean(Hyrax::ModelRegistry.admin_set_class_names)
          works.flat_map { |name| [name, "#{name}Resource"] }
        end
      end

      def clean(names)
        names.map { |name| name.to_s.delete_prefix('::') }
      end

      def warn_dead_property(reason)
        @warnings << "m3 profile declares a `redirects` property but #{reason}; " \
                     'the property will be ignored'
      end
    end
  end
end
