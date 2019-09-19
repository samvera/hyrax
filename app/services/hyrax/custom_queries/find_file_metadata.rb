module Hyrax
  module CustomQueries
    class FindFileMetadata
      # Use:
      #   Hyrax.query_service.custom_queries.find_file_metadata_by(id: valkyrie_id)
      #   Hyrax.query_service.custom_queries.find_file_metadata_by_alternate_identifier(alternate_identifier: alt_id)

      def self.queries
        [:find_file_metadata_by,
         :find_file_metadata_by_alternate_identifier]
      end

      def initialize(query_service:)
        @query_service = query_service
      end

      attr_reader :query_service
      delegate :resource_factory, to: :query_service

      def find_file_metadata_by(id:)
        query_service.find_by(id: id)
      end

      def find_file_metadata_by_alternate_identifier(alternate_id:)
        query_service.find_by_alternate_identifier(alternate_id: alternate_id)
      end
    end
  end
end
