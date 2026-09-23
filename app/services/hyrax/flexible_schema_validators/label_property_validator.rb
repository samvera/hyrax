# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    ##
    # @api private
    #
    # Validates that a `label` property exists and is available on
    # `Hyrax.config.file_set_model`.
    class LabelPropertyValidator < BaseValidator
      # @return [void]
      def validate!
        label_prop = profile.dig('properties', 'label')
        unless label_prop
          add_error 'A `label` property is required.'
          return
        end

        available_on_classes = label_prop.dig('available_on', 'class')
        return if available_on_classes&.include?(file_set_model_name)

        add_error "Label must be available on #{file_set_model_name}."
      end

      private

      def file_set_model_name
        @file_set_model_name ||= Hyrax.config.file_set_model.gsub(/^::/, '')
      end
    end
  end
end
