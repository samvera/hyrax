# frozen_string_literal: true

require 'hyrax/metadata/basic'
require 'hyrax/metadata/core'

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
    # This is a placeholder schema loader. it's here to help us define the API
    # for loading user defined schemas.
    #
    # @see https://github.com/samvera-labs/houndstooth
    class SimpleSchemaLoader
      SCHEMAS = {
        core_metadata: Hyrax::Metadata::Core.new,
        basic_metadata: Hyrax::Metadata::Basic.new
      }.freeze

      ##
      # @param [Symbol] schema
      def attributes_for(schema:)
        SCHEMAS[schema]&.attributes || raise(ArgumentError, "No schema defined: #{schema}")
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
