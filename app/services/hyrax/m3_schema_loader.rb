# frozen_string_literal: true

module Hyrax
  ##
  # @api private
  #
  # Read m3 profiles from the database
  #
  # @see config/metadata/m3_profile.yaml for an example configuration
  class M3SchemaLoader
    ##
    # @param [Symbol] schema
    #
    # @return [Hash<Symbol, Dry::Types::Type>] a map from attribute names to
    #   types
    def attributes_for(schema:, version: 1)
      definitions(schema, version).each_with_object({}) do |definition, hash|
        hash[definition.name] = definition.type.meta(definition.config)
      end
    end

    ##
    # @param [Symbol] schema
    #
    # @return [Hash{Symbol => Hash{Symbol => Object}}]
    def form_definitions_for(schema:, version: 1)
      definitions(schema, version).each_with_object({}) do |definition, hash|
        next if definition.form_options.empty?

        hash[definition.name] = definition.form_options
      end
    end

    ##
    # @param [Symbol] schema
    #
    # @return [{Symbol => Symbol}] a map from index keys to attribute names
    def index_rules_for(schema:, version: 1)
      definitions(schema, version).each_with_object({}) do |definition, hash|
        definition.index_keys.each do |key|
          hash[key] = definition.name
        end
      end
    end

    ##
    # @api private
    class AttributeDefinition
      ##
      # @!attr_reader :config
      #   @return [Hash<String, Object>]
      # @!attr_reader :name
      #   @return [#to_sym]
      attr_reader :config, :name

      ##
      # @param [#to_sym] name
      # @param [Hash<String, Object>] config
      def initialize(name, config)
        @config = config
        @name   = name.to_sym
      end

      ##
      # @return [Hash{Symbol => Object}]
      def form_options
        config.fetch('form', {}).symbolize_keys
      end

      ##
      # @return [Enumerable<Symbol>]
      def index_keys
        config.fetch('indexing', []).map(&:to_sym)
      end

      ##
      # @return [Dry::Types::Type]
      def type
        collection_type = if config['multi_value']
                            Valkyrie::Types::Array.constructor { |v| Array(v).select(&:present?) }
                          else
                            Identity
                          end
        collection_type.of(type_for(config['type']))
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

      private

      ##
      # Maps a configuration string value to a `Valkyrie::Type`.
      #
      # @param [String]
      # @return [Dry::Types::Type]
      def type_for(type)
        case type
        when 'id'
          Valkyrie::Types::ID
        when 'uri'
          Valkyrie::Types::URI
        when 'date_time'
          Valkyrie::Types::DateTime
        else
          "Valkyrie::Types::#{type.capitalize}".constantize
        end
      end
    end

    class UndefinedSchemaError < ArgumentError; end

    private

    ##
    # @param [#to_s] schema_name
    # @return [Enumerable<AttributeDefinition]
    def definitions(schema_name, version)
      Hyrax::FlexibleSchema.find_by(version: version).attributes_for(schema_name).map do |name, config|
        AttributeDefinition.new(name, config)
      end
    end
  end
end
