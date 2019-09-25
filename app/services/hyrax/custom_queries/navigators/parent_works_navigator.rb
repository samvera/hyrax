# Navigate from a resource to the child works in the resource.
module Hyrax
  module CustomQueries
    module Navigators
      class ParentWorksNavigator
        # Define the queries that can be fulfilled by this navigator.
        def self.queries
          [:find_parent_works, :find_parent_work_ids]
        end

        attr_reader :query_service

        def initialize(query_service:)
          @query_service = query_service
        end

        # Find parent works of a given resource, and map to Valkyrie Resources
        # @param [Valkyrie::Resource]
        # @return [Array<Valkyrie::Resource>]
        def find_parent_works(resource:)
          query_service.find_inverse_references_by(resource: resource, property: :member_ids).select(&:work?)
        end

        # Find the ids of parent works of a given resource, and map to Valkyrie Resources
        # @param [Valkyrie::Resource]
        # @return [Array<Valkyrie::ID>]
        def find_parent_work_ids(resource:)
          find_parent_works(resource: resource).map(&:id)
        end
      end
    end
  end
end
