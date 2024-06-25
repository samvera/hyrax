# frozen_string_literal: true
module Hyrax
  module CustomQueries
    # @example
    #   collection_type = Hyrax::CollectionType.find(1)
    #
    #   Hyrax.custom_queries.find_collections_by_type(global_id: Hyrax::GlobalID(collection_type))
    #
    # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
    class FindCollectionsByType
      def self.queries
        [:find_collections_by_type]
      end

      def initialize(query_service:)
        @query_service = query_service
      end

      attr_reader :query_service
      delegate :resource_factory, to: :query_service

      ##
      # @note this is an unoptimized default implementation of this custom
      #   query. it's Hyrax's policy to provide such implementations of custom
      #   queries in use for cross-compatibility of Valkyrie query services.
      #   it's advisable to provide an optimized query for the specific adapter.
      #
      # @param global_id [GlobalID] global id for a Hyrax::CollectionType
      #
      # @return [Enumerable<PcdmCollection>]
      def find_collections_by_type(global_id:, model: Hyrax.config.collection_class)
        query_service
          .find_all_of_model(model:)
          .select { |collection| collection.collection_type_gid == global_id }
      end
    end
  end
end
