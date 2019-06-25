# Navigate from a resource to the child collections in the resource.
module Hyrax
  module CustomQueries
    module Navigators
      class ChildCollectionsNavigator
        # Define the queries that can be fulfilled by this navigator.
        def self.queries
          [:find_child_collections, :find_child_collection_ids]
        end

        attr_reader :query_service

        def initialize(query_service:)
          @query_service = query_service
        end

        # Find child collections of a given resource, and map to Valkyrie Resources
        # @param [Valkyrie::Resource]
        # @return [Array<Valkyrie::Resource>]
        # TODO: By storing all children in a single relationship, it requires that the full resource be constructed for all children
        #       and then selecting only the children of a particular type to return.
        def find_child_collections(resource:)
          query_service.find_inverse_references_by(resource: resource, property: :member_of_collection_ids).select(&:collection?)
        end

        # Find the ids of child collections of a given resource, and map to Valkyrie Resources
        # @param [Valkyrie::Resource]
        # @return [Array<Valkyrie::ID>]
        # TODO: By storing all children in a single relationship, it requires that the full resource be constructed for all children
        #       and then selecting only the children of a particular type.  If we stored collections in a collections relationship and
        #       works in a works relationship, then a request for IDs would return all ids from the relationship and not instantiate
        #       any resources.
        def find_child_collection_ids(resource:)
          find_child_collections(resource: resource).map(&:id)
        end
      end
    end
  end
end
