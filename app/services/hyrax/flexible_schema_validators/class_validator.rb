# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    # Handles class-related validations for flexible metadata profiles
    class ClassValidator
      # @param profile [Hash] M3 profile data
      # @param required_classes [Array<String>] Foundational classes that must be present
      # @param errors [Array<String>] Array to append validation errors to
      def initialize(profile, required_classes, errors)
        @profile = profile
        @required_classes = required_classes
        @errors = errors
      end

      # Validates that referenced classes are registered Hyrax curation concern
      # types and that Valkyrie models use the correct `...Resource` naming
      # convention when applicable.
      #
      # @return [void]
      def validate_availability!
        classes_to_validate = all_profile_classes - @required_classes
        invalid_classes = []
        mismatched_valkyrie_classes = []

        classes_to_validate.each do |klass|
          validate_class(klass, invalid_classes, mismatched_valkyrie_classes)
        end

        report_mismatched_classes(mismatched_valkyrie_classes)
        report_invalid_classes(invalid_classes)
      end

      # Validates that all classes referenced within property `available_on`
      # definitions are themselves defined in the top-level `classes` section of
      # the profile.
      #
      # @return [void]
      def validate_references!
        properties = @profile['properties'] || {}

        referenced_classes = properties.values.flat_map do |prop|
          prop.dig('available_on', 'class')
        end.compact.uniq

        undefined_classes = referenced_classes - @profile['classes'].keys

        return if undefined_classes.empty?

        @errors << "Classes referenced in `available_on` but not defined in `classes`: #{undefined_classes.join(', ')}."
      end

      private

      # Gathers all unique class names from both the top-level `classes`
      # definition and all `available_on` property references.
      #
      # @return [Array<String>]
      def all_profile_classes
        profile_classes = @profile.fetch('classes', {}).keys
        properties = @profile['properties'] || {}
        available_on_classes = properties.values.flat_map do |prop|
          prop.dig('available_on', 'class')
        end.compact
        (profile_classes + available_on_classes).uniq
      end

      # Validates a single class, checking for registration as a curation concern
      # and for Valkyrie naming mismatches using the Valkyrie resolver.
      #
      # @param klass [String] the class name to validate
      # @param invalid_classes [Array<String>] an array to append invalid class errors to
      # @param mismatched_valkyrie_classes [Array<Hash>] an array to append Valkyrie mismatch errors to
      # @return [void]
      def validate_class(klass, invalid_classes, mismatched_valkyrie_classes)
        base_class_name = klass.gsub(/(?<=.)Resource$/, '')

        unless Hyrax.config.registered_curation_concern_types.include?(base_class_name)
          invalid_classes << klass
          return
        end

        begin
          expected_valkyrie_class = Valkyrie.config.resource_class_resolver.call(base_class_name)
          expected_class_name = expected_valkyrie_class.to_s

          mismatched_valkyrie_classes << { non_resource: klass, resource: expected_class_name } if klass != expected_class_name
        rescue NameError
          # This occurs if a registered concern doesn't have a loadable backing class,
          # which is an invalid state.
          invalid_classes << klass
        end
      end

      # Appends a formatted error message for any Valkyrie naming mismatches.
      #
      # @param mismatched_classes [Array<Hash>]
      # @return [void]
      def report_mismatched_classes(mismatched_classes)
        return if mismatched_classes.empty?

        message = mismatched_classes.map do |mismatch|
          "'#{mismatch[:non_resource]}' should be '#{mismatch[:resource]}'"
        end.join(', ')
        @errors << "Mismatched Valkyrie classes found: #{message}. If a Valkyrie model exists, the profile must use the '...Resource' class name."
      end

      # Appends a formatted error message for any invalid classes.
      #
      # @param invalid_classes [Array<String>]
      # @return [void]
      def report_invalid_classes(invalid_classes)
        return if invalid_classes.empty?

        @errors << "Invalid classes: #{invalid_classes.join(', ')}."
      end
    end
  end
end
