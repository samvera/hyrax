module Hyrax
  module CustomQueries
    class FindAccessControl
      def self.queries
        [:find_access_control_for]
      end

      def initialize(query_service:)
        @query_service = query_service
      end

      attr_reader :query_service
      delegate :resource_factory, to: :query_service

      def find_access_control_for(resource:)
        query_service
          .find_inverse_references_by(resource: resource, property: :access_to)
          .find { |r| r.is_a?(Hyrax::AccessControl) } ||
          raise(Valkyrie::Persistence::ObjectNotFoundError)
      end
    end
  end
end
