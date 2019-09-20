# frozen_string_literal: true

module Hyrax
  ##
  # @api private
  #
  # This is a simple yaml config-driven schema loader
  #
  # @see config/metadata/basic_metadata.yaml for an example configuration
  class SimpleSchemaLoader
    ##
    # @param [Symbol] schema
    def attributes_for(schema:)
      attributes = schema_config(schema)['attributes']

      attributes.each_with_object({}) do |(name, config), hash|
        collection_type = config['multiple'] ? Valkyrie::Types::Array : Identity

        hash[name.to_sym] = collection_type.of(type_for(config['type']))
      end
    end

    ##
    # @api private
    #
    # This class acts as a Valkyrie/Dry::Types collection with typed members,
    # but instead of wrapping the given type with itself as the collection type
    # (as in `Valkyrie::Types::Array.of(MyType)`), it returns the given type.
    #
    # @example
    #   Identity.of(Valkyrie::Types::String) # => Valkyrie::Types::String
    #
    class Identity
      ##
      # @param [Dry::Types::Type]
      # @return [Dry::Types::Type] the type passed in
      def self.of(type)
        type
      end
    end

    class UndefinedSchemaError < ArgumentError; end

    private

      ##
      # Maps a configuration string value to a `Valkyrie::Type`.
      #
      # @param [String]
      # @return [Dry::Types::Type]
      def type_for(type)
        case type
        when 'uri'
          Valkyrie::Types::URI
        when 'date_time'
          Valkyrie::Types::DateTime
        else
          "Valkyrie::Types::#{type.capitalize}".constantize
        end
      end

      def schema_config(schema_name)
        raise(UndefinedSchemaError, "No schema defined: #{schema_name}") unless
          File.exist?(config_path(schema_name))

        YAML.safe_load(File.open(config_path(schema_name)))
      end

      def config_path(schema_name)
        "config/metadata/#{schema_name}.yaml"
      end
  end
end
