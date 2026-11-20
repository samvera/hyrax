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

    # Run every validator in `Hyrax.config.flexible_schema_validators`, in
    # order, and populate {#errors} and {#warnings} with what they find.
    #
    # @return [void]
    def validate!
      validators.each { |validator_class| run_validator(validator_class) }
    end

    # @return [Array<Class>] the configured validators, with any registered by
    #   name resolved
    def validators
      Hyrax.config.flexible_schema_validators.map do |validator|
        validator.is_a?(String) ? validator.constantize : validator
      end
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
  end
end
