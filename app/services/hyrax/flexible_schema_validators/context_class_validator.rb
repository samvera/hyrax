# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    # Warns when a property limited to a context (`available_on: { context: }`)
    # is also available on collection, admin set or file set classes. A context
    # is set on an admin set for its works: collection and admin set pages ignore
    # context-limited properties, and file sets never receive a context.
    class ContextClassValidator < BaseValidator
      def self.legacy_positional_severity
        :warning
      end

      def validate!
        properties.each do |key, config|
          next if Array(config.dig('available_on', 'context')).empty?

          classes = Array(config.dig('available_on', 'class')).select { |name| classes_without_contexts.include?(name.to_s.delete_prefix('::')) }
          add_warning(:never_in_context, property: key, classes: classes.join(', ')) if classes.any?
        end
      end

      private

      def classes_without_contexts
        @classes_without_contexts ||= (Hyrax::ModelRegistry.collection_class_names + Hyrax::ModelRegistry.admin_set_class_names +
                                       Hyrax::ModelRegistry.file_set_class_names).map { |name| name.to_s.delete_prefix('::') }
      end
    end
  end
end
