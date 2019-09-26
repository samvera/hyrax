# Navigate from a resource to the child works in the resource.
module Hyrax
  module CustomQueries
    class FindRelated
      # Define the queries that can be fulfilled by this custom query.
      def self.queries
        [:find_related_for,
         :find_related_ids_for,
         :find_inverse_related_for,
         :find_inverse_related_ids_for]
      end

      attr_reader :query_service

      def initialize(query_service:)
        @query_service = query_service
      end

      # Find related resources, and map to Valkyrie Resources
      # @param [Valkyrie::Resource]
      # @return [Array<Valkyrie::Resource>]
      def find_related_for(resource:, relationship:)
        find_related_ids_for(resource: resource, relationship: relationship).map { |id| query_service.find_by(id: id) }
      end

      # Find ids for related resource
      # @param [Valkyrie::Resource]
      # @return [Array<Valkyrie::ID>]
      def find_related_ids_for(resource:, relationship:)
        (resource[relationship] || []).select { |x| x.is_a?(Valkyrie::ID) }
      end

      # Find the inverse related resources, and map to Valkyrie Resources.  These are other resources that have the
      # relationship attribute in their model that include this resource's id.
      # @param [Valkyrie::Resource]
      # @return [Array<Valkyrie::Resource>]
      def find_inverse_related_for(resource:, relationship:)
        query_service.find_inverse_references_by(resource: resource, property: relationship) || []
      end

      # Find ids for inverse related resource.  These are other resources that have the relationship attribute in their
      # model that include this resource's id.
      # @param [Valkyrie::Resource]
      # @return [Array<Valkyrie::ID>]
      def find_inverse_related_ids_for(resource:, relationship:)
        find_inverse_related_for(resource: resource, relationship: relationship).map(&:id)
      end
    end
  end
end
