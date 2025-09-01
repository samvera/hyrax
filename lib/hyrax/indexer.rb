# frozen_string_literal: true

module Hyrax
  ##
  # @api public
  #
  # Build an indexer module from a schema. Generates custom indexer behavior
  # from rules provided by `index_loader`.
  #
  # @param [Symbol] schema_name
  # @param [#index_rule_for] index_loader
  #
  # @return [Module]
  #
  # @example building a module as a mixin
  #
  #   class MyIndexer < Hyrax::Indexers::ResourceIndexer
  #     include Hyrax::Indexer(:core_metadata)
  #   end
  #
  # @example building a module as a mixin with flexible metadata
  #
  #   class MyIndexer < Hyrax::Indexers::ResourceIndexer
  #     include Hyrax::Indexer(:MyResource, index_loader: M3SchemaLoader.new)
  #   end
  #
  # @since 3.0.0
  def self.Indexer(schema_name, index_loader: SimpleSchemaLoader.new)
    Indexer.new(schema_name: schema_name, index_loader: index_loader)
  end

  ##
  # @api private
  #
  # @see .Indexer
  class Indexer < Module
    attr_accessor :schema_name, :index_loader

    ##
    # @param [Hash{Symbol => Symbol}] rules
    # @param [Symbol] schema_name
    # @param [#index_rule_for] index_loader
    #
    # @return [Module]
    def initialize(rules = nil, schema_name: nil, index_loader: nil)
      super()
      @schema_name = schema_name
      @index_loader = index_loader
      @rules = rules
      define_solr_method(schema_name:, index_loader:)
    end

    def define_solr_method(schema_name:, index_loader:) # rubocop:disable Metrics/MethodLength
      define_method :to_solr do |*args|
        super(*args).tap do |document|
          schema_args = if index_loader.is_a?(Hyrax::M3SchemaLoader)
                          document['schema_version_ssi'] = resource.schema_version
                          document['contexts_ssim'] = resource.contexts
                          { schema: resource.class.to_s, version: resource.schema_version, contexts: resource.contexts }
                        else
                          { schema: schema_name }
                        end
          rules = @rules || index_loader.index_rules_for(**schema_args)

          rules.each do |index_key, method|
            document[index_key] = resource.try(method)
          end
        end
      end
    end
  end
end
