# Navigate from a resource to the child works in the resource.
module Hyrax
  module CustomQueries
    module Navigators
      class ChildWorksNavigator
        # Define the queries that can be fulfilled by this navigator.
        def self.queries
          [:find_child_works, :find_child_work_ids]
        end

        attr_reader :query_service

        def initialize(query_service:)
          @query_service = query_service
        end

        # Find child works of a given resource, and map to Valkyrie Resources
        # @param [Valkyrie::Resource]
        # @return [Array<Valkyrie::Resource>]
        # TODO: By storing all children in a single relationship, it requires that the full resource be constructed for all children
        #       and then selecting only the children of a particular type to return.
        def find_child_works(resource:)
          query_service.find_members(resource: resource).select(&:work?)
        end

        # Find the ids of child works of a given resource, and map to Valkyrie Resources
        # @param [Valkyrie::Resource]
        # @return [Array<Valkyrie::ID>]
        # TODO: By storing all children in a single relationship, it requires that the full resource be constructed for all children
        #       and then selecting only the children of a particular type.  If we stored works in a works relationship and filesets
        #       in a filesets relationship, then a request for IDs would return all ids from the relationship and not instantiate
        #       any resources.
        def find_child_work_ids(resource:)
          find_child_works(resource: resource).map(&:id)
        end
      end
    end
  end
end
