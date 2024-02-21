# frozen_string_literal: true

module Hyrax
  module CustomQueries
    module Navigators
      ##
      # Navigate from a resource to the child filesets in the resource.
      #
      # @deprecated use Hyrax::CustomQueries::Navigators::ChildFileSetsNavigator instead
      # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
      # @since 3.0.0
      class ChildFilesetsNavigator
        # Define the queries that can be fulfilled by this navigator.
        def self.queries
          [:find_child_filesets, :find_child_fileset_ids]
        end

        attr_reader :query_service

        def initialize(*)
          @query_service = Hyrax.query_service
        end

        ##
        # Find child filesets of a given resource, and map to Valkyrie Resources
        #
        # @param [Valkyrie::Resource] resource
        #
        # @return [Array<Valkyrie::Resource>]
        # @deprecated
        def find_child_filesets(resource:)
          Deprecation.warn("Custom query find_child_filesets is deprecated; use find_child_file_sets instead.")
          query_service.custom_queries.find_child_file_sets(resource: resource)
        end

        ##
        # Find the ids of child filesets of a given resource, and map to Valkyrie Resources IDs
        #
        # @param [Valkyrie::Resource] resource
        #
        # @return [Array<Valkyrie::ID>]
        # @deprecated
        def find_child_fileset_ids(resource:)
          Deprecation.warn("Custom query find_child_fileset_ids is deprecated; use find_child_file_set_ids instead.")
          query_service.custom_queries.find_child_file_set_ids(resource: resource)
        end
      end
    end
  end
end
