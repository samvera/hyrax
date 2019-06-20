# frozen_string_literal: true
require 'rsolr'

module Valkyrie
  module Indexing
    module Solr
      class IndexingAdapter
        attr_reader :connection, :resource_indexer
        # @param connection [RSolr::Client] The RSolr connection to index to.
        # @param resource_indexer [Class, #to_solr] An indexer which is able to
        #   receive a `resource` argument and then has an instance method `#to_solr`
        def initialize(connection:, resource_indexer: Valkyrie::Persistence::Solr::MetadataAdapter::NullIndexer)
          @connection = connection
          @resource_indexer = resource_indexer
        end
      end
    end
  end
end
