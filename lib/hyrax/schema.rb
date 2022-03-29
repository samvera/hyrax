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
