# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    ##
    # @api private
    #
    # Validates the core metadata properties of a flexible metadata profile.
    class CoreMetadataValidator
      ##
      # @param profile [Hash] the flexible metadata profile
      # @param errors [Array<String>] an array to append errors to
      def initialize(profile:, errors:)
        @profile = profile
        @errors = errors
      end

      # Validate the profile against the core metadata requirements and append
      # any human-readable error messages to {#errors}.
      #
      # @return [void]
      def validate!
        core_metadata['attributes'].each do |property, config|
          next unless validate_property_exists(property)

          validate_property_multi_value(property, config)
          validate_property_indexing(property, config)
          validate_property_predicate(property, config)
          validate_property_available_on(property)
          validate_property_cardinality(property, config)
        end
        validate_keyword_property
      end

      private

      attr_reader :profile, :errors

      # Load and memoize the core metadata definition from
      # `config/metadata/core_metadata.yaml`.
      #
      # @return [Hash] the core metadata configuration with indifferent access
      def core_metadata
        return @core_metadata if @core_metadata

        @core_metadata = YAML.safe_load(
          File.read(Hyrax::Engine.root.join('config', 'metadata', 'core_metadata.yaml'))
        ).with_indifferent_access

        # Ensure the `creator` attribute is always treated as core metadata even
        # when it is not present in the YAML definition shipped with Hyrax.
        @core_metadata['attributes'] ||= {}

        @core_metadata['attributes']['creator'] ||= {
          'type' => 'string',
          'multiple' => true,
          'index_keys' => ['creator_sim', 'creator_tesim'],
          'predicate' => 'http://purl.org/dc/elements/1.1/creator'
        }

        @core_metadata
      end

      # Memoized convenience accessor that returns the class keys defined in
      # the profile.
      #
      # @return [Array<String>]
      def defined_classes
        @defined_classes ||= profile['classes'].keys
      end

      # Ensures the given property is present in the profile's `properties`
      # section.
      #
      # @param property [String, Symbol] the property name
      # @return [Boolean] true if the property exists, otherwise false
      def validate_property_exists(property)
        return true if profile['properties'][property].present?

        errors << "Missing required property: #{property}."
        false
      end

      # Validate that the property's `data_type` matches the expected type
      # based on the core metadata's `multiple` setting.
      #
      # @param property [String, Symbol] the property name
      # @param config [Hash] the core metadata configuration for the property
      # @return [void]
      def validate_property_multi_value(property, config)
        return unless config.key?("multiple")

        property_config = profile.dig('properties', property) || {}

        required_data_type = config['multiple'] ? 'array' : 'string'

        actual_data_type = determine_data_type_from_config(property_config)

        return if actual_data_type == required_data_type

        errors << "Property '#{property}' must have data_type set to '#{required_data_type}'."
      end

      # Determine the property's effective data type from its configuration.
      #
      # @param property_config [Hash] the property's configuration from the profile
      # @return [String] either 'array' or 'string'
      def determine_data_type_from_config(property_config)
        if property_config['data_type']
          property_config['data_type']
        elsif property_config['multi_value']
          'array'
        else
          'string'
        end
      end

      # Validate that the profile includes all indexing keys required by the
      # core metadata configuration.
      #
      # @param property [String, Symbol]
      # @param config [Hash]
      # @return [void]
      def validate_property_indexing(property, config)
        return unless config.key?('index_keys')

        profile_indexing = profile.dig('properties', property, 'indexing') || []
        missing_keys = config['index_keys'] - profile_indexing

        return if missing_keys.empty?

        errors << "Property '#{property}' is missing required indexing: #{missing_keys.join(', ')}."
      end

      # Ensures that the property's predicate matches the core metadata definition.
      #
      # @param property [String, Symbol]
      # @param config [Hash]
      # @return [void]
      def validate_property_predicate(property, config)
        return unless config.key?('predicate')
        return if profile.dig('properties', property, 'property_uri') == config['predicate']

        errors << "Property '#{property}' must have property_uri set to #{config['predicate']}."
      end

      # Validates that if the `keyword` property is present, it is correctly
      # configured as a multi-valued field.
      #
      # @return [void]
      def validate_keyword_property
        keyword_prop = profile.dig('properties', 'keyword')
        return unless keyword_prop

        return if keyword_prop['data_type'] == 'array'

        errors << "Property 'keyword' must have data_type set to 'array'."
      end

      # Checks that the property is available on all classes defined in the profile.
      #
      # @param property [String, Symbol]
      # @return [void]
      def validate_property_available_on(property)
        available_on_classes = profile.dig('properties', property, 'available_on', 'class') || []
        missing_classes = defined_classes - available_on_classes

        return if missing_classes.empty?
        errors << "Property '#{property}' must be available on all classes, but is missing from: #{missing_classes.join(', ')}."
      end

      # Validates the property's cardinality, ensuring that `title` is required
      # (i.e., has a minimum cardinality of 1).
      #
      # @param property [String, Symbol]
      # @param _config [Hash] the core metadata configuration for the property (unused)
      # @return [void]
      def validate_property_cardinality(property, _config)
        # Ensure that the `title` property is always required by enforcing
        # a cardinality minimum of at least 1.  According to the M3 profile
        # specification, `cardinality.minimum` > 0 is interpreted as
        # "required".
        return unless property.to_s == 'title'

        minimum = profile.dig('properties', property, 'cardinality', 'minimum')

        # Treat missing `cardinality` or `minimum` as 0 (i.e., not required).
        required = minimum.to_i.positive?
        return if required

        errors << "Property 'title' must have a cardinality minimum of at least 1."
      end
    end
  end
end
