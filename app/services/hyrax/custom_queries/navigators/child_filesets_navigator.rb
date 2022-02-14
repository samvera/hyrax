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
          [:find_child_file_sets, :find_child_file_set_ids,
           :find_child_filesets, :find_child_fileset_ids]
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
        def find_child_file_sets(resource:)
          query_service.find_members(resource: resource).select(&:file_set?)
        end
        alias find_child_filesets find_child_file_sets
        deprecation_deprecate find_child_filesets: "use find_child_file_sets instead"

        ##
        # Find the ids of child filesets of a given resource, and map to Valkyrie Resources IDs
        #
        # @param [Valkyrie::Resource] resource
        #
        # @return [Array<Valkyrie::ID>]
        def find_child_file_set_ids(resource:)
          find_child_file_sets(resource: resource).map(&:id)
        end
        alias find_child_fileset_ids find_child_file_set_ids
        deprecation_deprecate find_child_fileset_ids: "use find_child_file_set_ids instead"
      end
    end
  end
end
