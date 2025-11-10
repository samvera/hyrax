# frozen_string_literal: true

require 'set'

module Hyrax
  module FlexibleSchemaValidators
    # Validates that classes with existing records in the repository are not removed from the profile.
    class ExistingRecordsValidator
      # @param profile [Hash] M3 profile data
      # @param required_classes [Array<String>] Foundational classes that must be present
      # @param errors [Array<String>] Array to append validation errors to
      def initialize(profile, required_classes, errors)
        @profile = profile
        @required_classes = required_classes
        @errors = errors
      end

      # Validates that no classes with existing records in the repository have been
      # removed from the profile.
      #
      # @return [void]
      def validate!
        profile_classes_set = Set.new(@profile.fetch('classes', {}).keys)
        classes_with_records = []

        potential_existing_classes.each do |model_class|
          model_identifier = model_class.to_s
          counterpart_identifier = counterpart_for(model_identifier)

          # If this model or its counterpart is in the profile, we don't need to check it for removal.
          next if profile_classes_set.include?(model_identifier) || profile_classes_set.include?(counterpart_identifier)

          # If it's not in the profile, check if it has records.
          classes_with_records << model_identifier if model_has_records?(model_class, model_identifier)
        end

        return if classes_with_records.empty?

        @errors << "Classes with existing records cannot be removed from the profile: #{classes_with_records.uniq.join(', ')}."
      end

      private

      # Determines the counterpart model name (e.g., Image -> ImageResource).
      def counterpart_for(model_identifier)
        return unless defined?(Wings)

        klass = model_identifier.safe_constantize
        return if klass.blank?

        Wings::ModelRegistry.lookup(klass).to_s
      rescue NameError
        # This can happen if a class is not loadable,
        # or if a counterpart model does not exist.
        nil
      end

      # Queries the repository to see if a given model has any records.
      def model_has_records?(model_class, class_name)
        Hyrax.query_service.count_all_of_model(model: model_class).positive?
      rescue StandardError => e
        Rails.logger.error "Error checking records for #{class_name}: #{e.message}"
        false
      end

      # Gathers all unique, canonical model classes that could potentially have records.
      # @return [Array<Class>]
      def potential_existing_classes
        models = [
          Hyrax.config.file_set_model.constantize,
          Hyrax.config.admin_set_model.constantize,
          Hyrax.config.collection_model.constantize
        ].compact

        Hyrax.config.registered_curation_concern_types.each do |concern_type|
          models << Valkyrie.config.resource_class_resolver.call(concern_type)
        rescue NameError, LoadError
          # This can happen if a concern is registered but its class is not loadable.
          # We can safely ignore it, as it couldn't have records anyway.
          Rails.logger.warn "Could not resolve model class for registered concern: #{concern_type}"
        end

        models.uniq
      end
    end
  end
end
