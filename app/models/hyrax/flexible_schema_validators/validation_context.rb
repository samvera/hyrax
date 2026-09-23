# frozen_string_literal: true

module Hyrax
  module FlexibleSchemaValidators
    ##
    # @api private
    #
    # The inputs available to every profile validator.
    #
    # Validators take this single object rather than an argument list so that a
    # new input can be added here without changing the signature of all of them.
    ValidationContext = Struct.new(:profile, :schemer, :required_classes, keyword_init: true) do
      ##
      # Non-Hash entries are rejected here so validators can iterate without
      # repeating the guard.
      #
      # @return [Hash{String => Hash}] the profile's property definitions
      def properties
        (profile['properties'] || {}).select { |_name, config| config.is_a?(Hash) }
      end

      ##
      # @return [Array<String>] class names declared in the profile
      def class_names
        (profile['classes'] || {}).keys
      end
    end
  end
end
