# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    ##
    # @api private
    #
    # Validates that classes referenced in a profile are registered Hyrax
    # curation concern types, and that Valkyrie models use the correct
    # `...Resource` naming convention when applicable.
    class ClassAvailabilityValidator < BaseValidator
      # @return [void]
      def validate!
        classes_to_validate = all_profile_classes - required_classes - non_work_classes
        invalid_classes = []
        mismatched_valkyrie_classes = []

        classes_to_validate.each do |klass|
          validate_class(klass, invalid_classes, mismatched_valkyrie_classes)
        end

        report_mismatched_classes(mismatched_valkyrie_classes)
        report_invalid_classes(invalid_classes)
      end

      private

      # `validate_class` holds every class it is given to the curation concern
      # check, so these must be excluded. `required_classes` covers only the
      # configured collection/admin set/file set; a profile may legitimately name
      # others, since one migrating between collection classes carries both.
      #
      # @return [Array<String>]
      def non_work_classes
        clean_class_names(Hyrax::ModelRegistry.collection_class_names +
                          Hyrax::ModelRegistry.admin_set_class_names +
                          Hyrax::ModelRegistry.file_set_class_names)
      end

      # @param klass [String]
      # @return [Boolean] whether the named class resolves to a collection,
      #   admin set, or file set model rather than a work type.
      def non_work_model?(klass)
        constant = klass.safe_constantize
        return false if constant.nil?

        constant.respond_to?(:pcdm_collection?) && constant.pcdm_collection? ||
          constant.respond_to?(:file_set?) && constant.file_set?
      end

      # Gathers all unique class names from both the top-level `classes`
      # definition and all `available_on` property references.
      #
      # @return [Array<String>]
      def all_profile_classes
        available_on_classes = properties.values.flat_map do |prop|
          prop.dig('available_on', 'class')
        end.compact

        clean_class_names(class_names + available_on_classes).uniq
      end

      def clean_class_names(names)
        names.map { |name| name.to_s.strip.gsub(/^::/, '') }
      end

      # Validates a single class, checking for registration as a curation concern
      # and for Valkyrie naming mismatches using the Valkyrie resolver.
      #
      # @param klass [String] the class name to validate
      # @param invalid_classes [Array<String>] an array to append invalid class errors to
      # @param mismatched_valkyrie_classes [Array<Hash>] an array to append Valkyrie mismatch errors to
      # @return [void]
      def validate_class(klass, invalid_classes, mismatched_valkyrie_classes)
        # Catches a collection or admin set class that is in neither
        # `required_classes` nor the registry, which `non_work_classes` cannot
        # exclude by name.
        return if non_work_model?(klass)

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

      # @param mismatched_classes [Array<Hash>]
      # @return [void]
      def report_mismatched_classes(mismatched_classes)
        return if mismatched_classes.empty?

        message = mismatched_classes.map do |mismatch|
          "'#{mismatch[:non_resource]}' should be '#{mismatch[:resource]}'"
        end.join(', ')
        add_error "Mismatched Valkyrie classes found: #{message}."
      end

      # @param invalid_classes [Array<String>]
      # @return [void]
      def report_invalid_classes(invalid_classes)
        return if invalid_classes.empty?

        add_error "Invalid classes: #{invalid_classes.join(', ')}."
      end
    end
  end
end
