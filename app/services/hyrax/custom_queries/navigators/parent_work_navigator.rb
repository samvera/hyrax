# frozen_string_literal: true

module Hyrax
  module CustomQueries
    module Navigators
      ##
      # Navigate from a resource to it's parent work.
      #
      # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
      # @since 3.4.0
      class ParentWorkNavigator
        # Define the queries that can be fulfilled by this navigator.
        def self.queries
          [:find_parent_work, :find_parent_work_id]
        end

        attr_reader :query_service

        def initialize(query_service:)
          @query_service = query_service
        end

        ##
        # Find parent work of a given resource, and map to Valkyrie Resources
        # @note There should be only one parent resource.  A warning is logged if
        #   more than one resource is found and the first of the resources is returned.
        # @param [Valkyrie::Resource] resource
        #
        # @return [Array<Valkyrie::Resource>]
        def find_parent_work(resource:)
          results = Hyrax.query_service.find_inverse_references_by(resource: resource,
                                                                   property: :member_ids).select(&:work?)
          if results.count > 1
            Hyrax.logger.warn("#{resource.work? ? 'Work' : 'File set'} " \
                              "#{resource.id} is in #{results.count} works when it " \
                              "should be in no more than one. Found in #{results.map(&:id).join(', ')}.")
          end
          results.first
        end

        ##
        # Find the id of the parent work of a given resource, and map to Valkyrie Resources IDs
        # @note There should be only one parent resource.  A warning is logged if
        #   more than one resource is found and the first of the resources is returned.
        # @param [Valkyrie::Resource] resource
        #
        # @return [Array<Valkyrie::ID>]
        def find_parent_work_id(resource:)
          find_parent_work(resource: resource)&.id
        end
      end
    end
  end
end
