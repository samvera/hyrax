# frozen_string_literal: true

module Hyrax
  ##
  # @param [Symbol] schema_name
  #
  # @return [Module]
  #
  # @example
  #   class Monograph < Valkyrie::Resource
  #     include Hyrax::Schema(:book)
  #   end
  #
  # @since 3.0.0
  def self.Schema(schema_name, **options)
    Hyrax::Schema.new(schema_name, **options)
  end

  ##
  # Specify a schema
  class Schema < Module
    ##
    # @!attribute [r] name
    #   @return [Symbol]
    attr_reader :name

    ##
    # @param [Symbol] schema_name
    #
    # @note use Hyrax::Schema(:my_schema) instead
    #
    # @api private
    def initialize(schema_name, schema_loader: SimpleSchemaLoader.new)
      @name = schema_name
      @schema_loader = schema_loader
    end

    ##
    # @return [Hash{Symbol => Dry::Types::Type}]
    def attributes
      @schema_loader.attributes_for(schema: name)
    end

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
          wrapper = config['multiple'] ? Valkyrie::Types::Array : NullWrapper

          hash[name.to_sym] = wrapper.of(type_for(config['type']))
        end
      end

      ##
      # @api private
      class NullWrapper
        def self.of(content_type)
          content_type
        end
      end

      private

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
          raise(ArgumentError, "No schema defined: #{schema_name}") unless
            File.exist?(config_path(schema_name))

          YAML.safe_load(File.open(config_path(schema_name)))
        end

        def config_path(schema_name)
          "config/metadata/#{schema_name}.yaml"
        end
    end

    private

      ##
      # @param [Module] descendant
      #
      # @api private
      def included(descendant)
        super
        descendant.attributes(attributes)
      end
  end
end
