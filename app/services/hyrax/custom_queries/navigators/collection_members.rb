# frozen_string_literal: true

module Hyrax
  module CustomQueries
    module Navigators
      ##
      # Find members of collections and collections for members
      #
      # @since 3.0.0
      class CollectionMembers
        ##
        # @return [Array<Symbol>
        def self.queries
          [:find_child_works, :find_child_work_ids]
        end
        ##
        # @!attribute [r] query_service
        #   @return [#custom_queries]
        attr_reader :query_service

        def initialize(query_service:)
          @query_service = query_service
        end

        ##
        # Find child works of a given resource, and map to Valkyrie Resources
        #
        # @param [Valkyrie::Resource] resource
        # @return [Array<Valkyrie::Resource>]
        def find_collections_for(resource:)
          query_service
            .find_references_by(resource: resource, property: :member_of_collection_ids)
        end

        ##
        # Find members for the given collection
        #
        # @param [Valkyrie::Resource] collection
        # @return [Array<Valkyrie::Resource>]
        def find_members_of(collection:)
          query_service
            .find_inverse_references_by(resource: collection, property: :member_of_collection_ids)
        end
      end
    end
  end
end
