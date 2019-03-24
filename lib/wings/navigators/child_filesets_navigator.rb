# Navigate from a resource to the child filesets in the resource.
module Wings
  class ChildFilesetsNavigator
    # Define the queries that can be fulfilled by this navigator.
    def self.queries
      [:find_child_filesets, :find_child_fileset_ids]
    end

    attr_reader :query_service

    def initialize(query_service:)
      @query_service = query_service
    end

    # Find child filesets of a given resource, and map to Valkyrie Resources
    # @param [Valkyrie::Resource]
    # @return [Array<Valkyrie::Resource>]
    # TODO: By storing all children in a single relationship, it requires that the full resource be constructed for all children
    #       and then selecting only the children of a particular type to return.
    def find_child_filesets(resource:)
      query_service.find_members(resource: resource).select(&:file_set?)
    end

    # Find the ids of child filesets of a given resource, and map to Valkyrie Resources
    # @param [Valkyrie::Resource]
    # @return [Array<Valkyrie::ID>]
    # TODO: By storing all children in a single relationship, it requires that the full resource be constructed for all children
    #       and then selecting only the children of a particular type.  If we stored works in a works relationship and filesets
    #       in a filesets relationship, then a request for IDs would return all ids from the relationship and not instantiate
    #       any resources.
    def find_child_fileset_ids(resource:)
      find_child_filesets(resource: resource).map(&:id)
    end
  end
end
