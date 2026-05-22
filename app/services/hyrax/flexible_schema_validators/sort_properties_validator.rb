# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    class SortPropertiesValidator
      attr_reader :profile, :sort_properties

      def initialize(profile, warnings)
        @profile = profile
        @warnings = warnings
        @sort_properties = find_sort_properties
      end

      def validate!
        sort_properties.each do |property|
          properties_without_sort_properties = work_types_from_profile - (profile.dig('properties', property, 'available_on', 'class') || [])
          next if properties_without_sort_properties.empty?

          msg = I18n.t(
            'hyrax.flexible_schema_validators.sort_properties_validator.warnings.message',
            property: property,
            classes: properties_without_sort_properties.join(', ')
          )
          @warnings << msg
        end
      end

      private

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
