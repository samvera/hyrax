# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    class SortPropertiesValidator < BaseValidator
      def self.legacy_positional_severity
        :warning
      end

      def validate!
        sort_properties.each do |property|
          properties_without_sort_properties = work_types_from_profile - (profile.dig('properties', property, 'available_on', 'class') || [])
          next if properties_without_sort_properties.empty?

          add_warning(:message,
                      property: property,
                      classes: properties_without_sort_properties.join(', '))
        end
      end

      private

      # Resolved on demand rather than in a constructor: building a validator
      # should not reach into Blacklight's configuration.
      def sort_properties
        @sort_properties ||= find_sort_properties
      end

      def find_sort_properties
        CatalogController.blacklight_config.sort_fields.keys.filter_map do |sort_key|
          field = sort_key.split.first.sub(/_[^_]*$/, '')
          field unless system_properties.include?(field)
        end.uniq
      end

      def system_properties
        %w[score system_modified system_create]
      end

      def work_types_from_profile
        work_types = available_works.map do |work_type|
          Valkyrie.config.resource_class_resolver.call(work_type).to_s
        end

        profile['classes'].keys.filter_map { |klass_name| klass_name if work_types.include?(klass_name) }
      end

      def available_works
        Hyrax.config.registered_curation_concern_types
      end
    end
  end
end
