# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    ##
    # @api private
    #
    # Validates that all classes referenced within property `available_on`
    # definitions are themselves defined in the top-level `classes` section of
    # the profile.
    class ClassReferenceValidator < BaseValidator
      # @return [void]
      def validate!
        referenced_classes = properties.values.flat_map do |prop|
          prop.dig('available_on', 'class')
        end.compact.uniq

        undefined_classes = referenced_classes - class_names

        return if undefined_classes.empty?

        add_error "Classes referenced in `available_on` but not defined in `classes`: #{undefined_classes.join(', ')}."
      end
    end
  end
end
