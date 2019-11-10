# frozen_string_literal: true

module Hyrax
  ##
  # @public
  #
  # @since 3.0.0
  def self.Indexer(schema_name, index_loader: SimpleSchemaLoader.new)
    Indexer.new(index_loader.index_rules_for(schema: schema_name))
  end

  ##
  # @private
  class Indexer < Module
    ##
    # @param [Symbol] schema
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
