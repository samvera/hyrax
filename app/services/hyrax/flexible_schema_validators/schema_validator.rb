# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    # Handles JSON schema validation for flexible metadata profiles
    class SchemaValidator
      def initialize(schemer, profile, errors)
        @schemer = schemer
        @profile = profile
        @errors = errors
      end

      def validate!
        @schemer.validate(@profile).to_a&.each do |error|
          pointer = error['data_pointer']
          type = error['type']

          if pointer.end_with?('/available_on') && error['data'].nil? && type == 'object'
            @errors << "Schema error at `#{pointer}`: `available_on` cannot be empty and must have a `class` or `context` sub-property."
          elsif type == 'required'
            missing_keys = error.dig('details', 'missing_keys')&.join("', '")
            @errors << "Schema error at `#{pointer}`: Missing required properties: '#{missing_keys}'."
          else
            @errors << "Schema error at `#{pointer}`: Invalid value `#{error['data'].inspect}` for type `#{type}`."
          end
        end
      end

      private

      attr_reader :schemer, :profile, :errors
    end
  end
end
