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
  # @since 3.0.0
  def self.Indexer(schema_name, index_loader: SimpleSchemaLoader.new)
    Indexer.new(index_loader.index_rules_for(schema: schema_name))
  end

  ##
  # @api private
  #
  # @see .Indexer
  class Indexer < Module
    ##
    # @param [Hash{Symbol => Symbol}] rules
    def initialize(rules)
      define_method :to_solr do |*args|
        super(*args).tap do |document|
          rules.each do |index_key, method|
            document[index_key] = resource.try(method)
          end
        end
      end
    end
  end
end
