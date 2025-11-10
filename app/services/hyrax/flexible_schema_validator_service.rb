# frozen_string_literal: true

require 'json_schemer'
require_relative 'core_metadata_validator'
require_relative 'flexible_schema_validators/schema_validator'
require_relative 'flexible_schema_validators/class_validator'
require_relative 'flexible_schema_validators/existing_records_validator'

module Hyrax
  class FlexibleSchemaValidatorService
    DEFAULT_SCHEMA = Rails.root.join('lib', 'flexible', 'm3_json_schema.json')
    REQUIRED_CLASSES = [
      Hyrax.config.admin_set_model,
      Hyrax.config.collection_model,
      Hyrax.config.file_set_model
    ].map { |str| str.gsub(/^::/, '') }

    attr_reader :profile, :schema, :schemer, :errors

    # Initializes a new FlexibleSchemaValidatorService.
    #
    # @param profile [Hash] the flexible metadata profile to validate
    # @param schema [Pathname, String] the JSON schema to validate against.
    #   Defaults to {DEFAULT_SCHEMA}.
    # @return [void]
    def initialize(profile:, schema: default_schema)
      @profile = profile
      @schema = schema
      @schemer = JSONSchemer.schema(schema)
      @errors = []
    end

    # Execute all validation routines and populate {#errors} with any
    # issues discovered.
    #
    # @return [void]
    def validate!
      validate_required_classes
      validate_class_availability
      validate_available_on_classes_defined
      validate_existing_records_classes_defined
      validate_schema
      validate_label_prop
      validate_core_metadata
    end

    # The default JSON schema used when no custom schema is provided.
    #
    # @return [Pathname]
    def default_schema
      DEFAULT_SCHEMA
    end

    # Classes that MUST be present in every flexible metadata profile.
    #
    # @return [Array<String>]
    def required_classes
      REQUIRED_CLASSES
    end

    private

    # Validates core metadata requirements using the CoreMetadataValidator.
    #
    # This delegates to CoreMetadataValidator to check that essential metadata
    # properties are properly configured across all classes in the profile.
    #
    # @return [void]
    def validate_core_metadata
      CoreMetadataValidator.new(profile: profile, errors: @errors).validate!
    end

    # Runs JSON schema validation and translates resulting errors into
    # user-friendly messages appended to {#errors}.
    #
    # @return [void]
    def validate_schema
      FlexibleSchemaValidators::SchemaValidator.new(schemer, profile, @errors).validate!
    end

    # Ensures that all required classes are defined in the profile.
    #
    # @return [void]
    def validate_required_classes
      missing_classes = required_classes - profile['classes'].keys
      return if missing_classes.empty?

      @errors << "Missing required classes: #{missing_classes.join(', ')}."
    end

    # Checks that any class referenced in the profile is a registered
    # Hyrax curation concern type.
    #
    # @return [void]
    def validate_class_availability
      FlexibleSchemaValidators::ClassValidator.new(profile, required_classes, @errors).validate_availability!
    end

    # Validates that every class referenced under `available_on.class` is also
    # defined in the profile's top-level `classes` section.
    #
    # @return [void]
    def validate_available_on_classes_defined
      FlexibleSchemaValidators::ClassValidator.new(profile, required_classes, @errors).validate_references!
    end

    # Delegates to {ExistingRecordsValidator} to ensure that no classes with
    # existing repository records have been removed from the profile.
    #
    # @return [void]
    def validate_existing_records_classes_defined
      FlexibleSchemaValidators::ExistingRecordsValidator.new(profile, required_classes, @errors).validate!
    end

    # Validates that a `label` property exists and that it is available on
    # `Hyrax::FileSet`.
    #
    # @return [void]
    def validate_label_prop
      label_prop = profile.dig('properties', 'label')
      unless label_prop
        @errors << "A `label` property is required."
        return
      end

      available_on_classes = label_prop.dig('available_on', 'class')
      return if available_on_classes&.include?('Hyrax::FileSet')

      @errors << "Label must be available on Hyrax::FileSet."
    end
  end
end
