# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    ##
    # @api private
    #
    # Validates that every class Hyrax requires — the configured admin set,
    # collection, and file set models — is declared in the profile.
    class RequiredClassesValidator < BaseValidator
      # @return [void]
      def validate!
        missing_classes = clean_class_names(required_classes) - clean_class_names(class_names)
        return if missing_classes.empty?

        add_error "Missing required classes: #{missing_classes.join(', ')}."
      end

      private

      def clean_class_names(names)
        names.map { |name| name.to_s.strip.gsub(/^::/, '') }
      end
    end
  end
end
