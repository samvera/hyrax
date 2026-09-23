# frozen_string_literal: true

module Hyrax
  class FlexibleSchemaValidatorService
    DEFAULT_SCHEMA = Hyrax::Engine.root.join('config', 'metadata_profiles', 'm3_json_schema.json')
    REQUIRED_CLASSES = [
      Hyrax.config.admin_set_model,
      Hyrax.config.collection_model,
      Hyrax.config.file_set_model
    ].map { |str| str.gsub(/^::/, '') }

    attr_reader :profile, :schema, :schemer, :errors, :warnings

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
      @warnings = []
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
      validate_sort_properties
      validate_redirects
      validate_compound
      validate_rich_text
      validate_search_results_truncate
      validate_render_as
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

    # @param validator_class [Class]
    # @return [void]
    def run_validator(validator_class)
      violations = validator_class.new(validation_context).tap(&:validate!).violations

      @errors.concat(violations.select(&:error?).map(&:message))
      @warnings.concat(violations.select(&:warning?).map(&:message))
    end

    # Built on first use rather than in the constructor, so that a
    # {#required_classes} override applied after construction is still picked up.
    #
    # @return [FlexibleSchemaValidators::ValidationContext]
    def validation_context
      @validation_context ||= FlexibleSchemaValidators::ValidationContext.new(
        profile: profile, schemer: schemer, required_classes: required_classes
      )
    end

    # Validates core metadata requirements using the CoreMetadataValidator.
    #
    # This delegates to CoreMetadataValidator to check that essential metadata
    # properties are properly configured across all classes in the profile.
    #
    # @return [void]
    def validate_core_metadata
      run_validator(FlexibleSchemaValidators::CoreMetadataValidator)
    end

    # Runs JSON schema validation and translates resulting errors into
    # user-friendly messages appended to {#errors}.
    #
    # @return [void]
    def validate_schema
      run_validator(FlexibleSchemaValidators::SchemaValidator)
    end

    # Ensures that all required classes are defined in the profile.
    #
    # @return [void]
    def validate_required_classes
      run_validator(FlexibleSchemaValidators::RequiredClassesValidator)
    end

    # Checks that any class referenced in the profile is a registered
    # Hyrax curation concern type.
    #
    # @return [void]
    def validate_class_availability
      run_validator(FlexibleSchemaValidators::ClassAvailabilityValidator)
    end

    # Validates that every class referenced under `available_on.class` is also
    # defined in the profile's top-level `classes` section.
    #
    # @return [void]
    def validate_available_on_classes_defined
      run_validator(FlexibleSchemaValidators::ClassReferenceValidator)
    end

    # Delegates to {ExistingRecordsValidator} to ensure that no classes with
    # existing repository records have been removed from the profile.
    #
    # @return [void]
    def validate_existing_records_classes_defined
      run_validator(FlexibleSchemaValidators::ExistingRecordsValidator)
    end

    # Validates that any properties needed to support sorting catalog search results.
    #
    # @return [void]
    def validate_sort_properties
      run_validator(FlexibleSchemaValidators::SortPropertiesValidator)
    end

    # Validates that the `redirects` property is declared on every work and
    # collection class when both `Hyrax.config.redirects_enabled?` and
    # `Flipflop.redirects?` are true. When either gate is closed, this
    # validator is a no-op.
    #
    # @return [void]
    def validate_redirects
      run_validator(FlexibleSchemaValidators::RedirectsValidator)
    end

    # Validates compound (hierarchical) metadata properties — those declaring
    # `subproperties:` — for well-formed sub-properties and correct
    # (per-sub-property) indexing declaration.
    #
    # @return [void]
    def validate_compound
      run_validator(FlexibleSchemaValidators::CompoundValidator)
    end

    # Warns (does not block) when a property declares
    # `form: { input_type: rich_text }` alongside a controlled-vocabulary
    # configuration, since rich text stores free-form HTML and bypasses the
    # controlled input.
    #
    # @return [void]
    def validate_rich_text
      run_validator(FlexibleSchemaValidators::RichTextValidator)
    end

    # Warns (does not block) when `view: { search_results_truncate: N }` is
    # declared without `view: { render_as: html }`, where the setting is a
    # silent no-op.
    #
    # @return [void]
    def validate_search_results_truncate
      run_validator(FlexibleSchemaValidators::SearchResultsTruncateValidator)
    end

    # Warns (does not block) when a property's `view: { render_as: ... }` needs
    # indexing the property does not declare, or conflicts with the vocabulary
    # behind it.
    #
    # @return [void]
    def validate_render_as
      run_validator(FlexibleSchemaValidators::RenderAsValidator)
    end

    # Validates that a `label` property exists and that it is available on
    # `Hyrax.config.file_set_model`.
    #
    # @return [void]
    def validate_label_prop
      run_validator(FlexibleSchemaValidators::LabelPropertyValidator)
    end
  end
end
