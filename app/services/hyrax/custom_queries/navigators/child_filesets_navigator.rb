# frozen_string_literal: true

module Hyrax
  module CustomQueries
    module Navigators
      ##
      # Navigate from a resource to the child filesets in the resource.
      #
      # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
      # @since 3.0.0
      class ChildFilesetsNavigator
        # Define the queries that can be fulfilled by this navigator.
        def self.queries
          [:find_child_filesets, :find_child_fileset_ids]
        end

        attr_reader :query_service

        def initialize(query_service:)
          @query_service = query_service
        end

        ##
        # Find child filesets of a given resource, and map to Valkyrie Resources
        #
        # @param [Valkyrie::Resource] resource
        #
        # @return [Array<Valkyrie::Resource>]
        def find_child_filesets(resource:)
          query_service.find_members(resource: resource).select(&:file_set?)
        end

        ##
        # Find the ids of child filesets of a given resource, and map to Valkyrie Resources IDs
        #
        # @param [Valkyrie::Resource] resource
        #
        # @return [Array<Valkyrie::ID>]
        def find_child_fileset_ids(resource:)
          find_child_filesets(resource: resource).map(&:id)
        end
      end
    end
  end
end
