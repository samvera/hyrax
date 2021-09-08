# frozen_string_literal: true

module Hyrax
  module CustomQueries
    module Navigators
      ##
      # Navigate from a resource to the parent collections of the resource.
      #
      # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
      # @since 3.0.0
      class ParentCollectionsNavigator
        # Define the queries that can be fulfilled by this navigator.
        def self.queries
          [:find_parent_collections, :find_parent_collection_ids]
        end

        attr_reader :query_service

        def initialize(query_service:)
          @query_service = query_service
        end

        ##
        # Find parent collections of a given resource, and map to Valkyrie Resources
        #
        # @param [Valkyrie::Resource] resource
        #
        # @return [Array<Valkyrie::Resource>]
        def find_parent_collections(resource:)
          query_service
            .find_many_by_ids(ids: find_parent_collection_ids(resource: resource))
        end

        ##
        # Find the ids of parent collections of a given resource, and map to Valkyrie Resources IDs
        #
        # @param [Valkyrie::Resource] resource
        #
        # @return [Array<Valkyrie::ID>]
        def find_parent_collection_ids(resource:)
          resource.member_of_collection_ids
        end
      end
    end
  end
end
