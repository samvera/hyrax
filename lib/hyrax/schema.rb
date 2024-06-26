# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # Builds a schema module for a +Valkyrie::Resource+. The schema itself is
  # resolved by a schema loader instance, which must implement
  # {SimpleSchemaLoader#attributes_for}, with a hash from attribute names to
  # +Dry::Type+ types.
  #
  # For the default schema loader, configuration is loaded from
  # +config/metadata/{name}.yaml+. A custom schema loader can be provided as
  # +:schema_loader+ to
  # resolve the schema in other ways.
  #
  # @note +Valkyrie::Resource+ and {Hyrax::Resource} classes are not required to
  #   use this interface, and may define custom attributes using the base
  #   +Valkyrie::Resource.attribute+ interface. This mechanism is provided to
  #   allow schemas to be defined in a unified way that don't require programmer
  #   intervention ("configurable schemas"). While the default schema loader derives
  #   schemas from configuration files, alternate implementations could provide
  #   schema definitions pulled from repository storage, an external schema service,
  #   etc...
  #
  # @param [Symbol] schema_name
  # @param [#attributes_for] schema_loader
  #
  # @return [Module] a module that, when included, applies a schema to a
  #   `Valkyire::Resource`
  #
  # @example
  #   class Monograph < Valkyrie::Resource
  #     include Hyrax::Schema(:book)
  #   end
  #
  # @example with a custom schema loader
  #   class Monograph < Valkyrie::Resource
  #     include Hyrax::Schema(:book, schema_loader: MySchemaLoader.new)
  #   end
  #
  # @since 3.0.0
  def self.Schema(schema_name, **options)
    Hyrax::Schema.new(schema_name, **options)
  end

  ##
  # @api private
  #
  # A module specifying a Schema (set of attributes and types) that can be
  # applied to a `Valkyrie::Resource`. This provides the internals for the
  # recommended module builder syntax: `Hyrax::Schema(:schema_name)`
  #
  # @see .Schema
  class Schema < Module
    ##
    # @!attribute [r] name
    #   @return [Symbol]
    attr_reader :name, :version

    ##
    # Pick the default schema loader based on whether flex is on or not
    def self.default_schema_loader
      Hyrax.config.flexible? ? M3SchemaLoader.new : SimpleSchemaLoader.new
    end

    ##
    # @param [Hyrax::Resource] work_type
    #
    # @example Hyrax::Schema.schema_to_hash(Monograph)
    #
    # @return [Hash{String => Hash}]
    def self.schema_to_hash_for(work_type)
      return unless work_type.respond_to?(:schema)

      schema = work_type.schema
      schema.each_with_object({}) do |property, metadata|
        metadata[property.name.to_s] = property.meta
      end
    end

    ##
    # @param [Symbol] schema_name
    #
    # @note use Hyrax::Schema(:my_schema) instead
    #
    # @api private
    def initialize(schema_name, schema_loader: Hyrax::Schema.default_schema_loader, schema_version: '1')
      @name = schema_name.to_s
      @version = schema_version
      @schema_loader = schema_loader
    end

    ##
    # @return [Hash{Symbol => Dry::Types::Type}]
    def attributes
      @schema_loader.attributes_for(schema: name, version:)
    end

    ##
    # @return [String]
    def inspect
      "#{self.class}(#{@name})"
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
