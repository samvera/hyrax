module Wings
  module CustomQueries
    class FindAccessControl
      # Custom query override specific to Wings
      # Use:
      #   Hyrax.custom_queries.find_access_control_for(resource: resource)

      def self.queries
        [:find_access_control_for]
      end

      attr_reader :query_service
      delegate :resource_factory, to: :query_service

      def initialize(query_service:)
        @query_service = query_service
      end

      ##
      # Wings needs special handling for this query, since `Hydra::AccessControl`
      # relationship direction is inverted from the `Hyrax::AccessControl`. We
      # need to query from the `access_control_id` stored on the resource,
      # instead of doing an `inverse_references_by` lookup.
      #
      # @param resource [Valkyrie::Resource] find access control for this resource
      # @return [Valkyrie::Resource] the access control resource
      # @raise [Valkyrie::Persistence::ObjectNotFoundError]
      def find_access_control_for(resource:)
        if resource.respond_to?(:access_control_id)
          raise ::Valkyrie::Persistence::ObjectNotFoundError if resource.access_control_id.blank?
          result = query_service.find_by(id: resource.access_control_id)
          result.access_to = resource.id # access_to won't be set in wings if there are no permissions
          result
        else
          raise ::Valkyrie::Persistence::ObjectNotFoundError,
                "#{resource.internal_resource} is not a `Hydra::AccessControls::Permissions` implementer"
        end
      end
    end
  end
end
