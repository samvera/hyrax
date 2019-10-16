module Hyrax
  module CustomQueries
    class FindFileMetadata
      # Use:
      #   Hyrax.query_service.custom_queries.find_file_metadata_by(id: valkyrie_id)
      #   Hyrax.query_service.custom_queries.find_file_metadata_by_alternate_identifier(alternate_identifier: alt_id)
      #   Hyrax.query_service.custom_queries.find_many_file_metadata_by_ids(ids: [valkyrie_id, valkyrie_id])

      def self.queries
        [:find_file_metadata_by,
         :find_file_metadata_by_alternate_identifier,
         :find_many_file_metadata_by_ids]
      end

      def initialize(query_service:)
        @query_service = query_service
      end

      attr_reader :query_service
      delegate :resource_factory, to: :query_service

      # Find a file metadata using a Valkyrie ID, and map it to a Hyrax::FileMetadata
      # @param [Valkyrie::ID, String] id
      # @return [Hyrax::FileMetadata]
      # @raise [Hyrax::ObjectNotFoundError]
      def find_file_metadata_by(id:)
        result = query_service.find_by(id: id)
        unless result.is_a? Hyrax::FileMetadata
          raise ::Valkyrie::Persistence::ObjectNotFoundError,
                "Result type #{result.internal_resource} for given id is not a `Hyrax::FileMetadata`"
        end
        result
      end

      # Find a file metadata using an alternate ID, and map it to a Hyrax::FileMetadata
      # @param [Valkyrie::ID, String] id
      # @return [Hyrax::FileMetadata]
      # @raise [Hyrax::ObjectNotFoundError]
      def find_file_metadata_by_alternate_identifier(alternate_identifier:)
        result = query_service.find_by_alternate_identifier(alternate_identifier: alternate_identifier)
        unless result.is_a? Hyrax::FileMetadata
          raise ::Valkyrie::Persistence::ObjectNotFoundError,
                "Result type #{result.internal_resource} for given id is not a `Hyrax::FileMetadata`"
        end
        result
      end

      # Find an array of file metadata using Valkyrie IDs, and map them to Hyrax::FileMetadata maintaining order based on given ids
      # @param [Array<Valkyrie::ID, String>] ids
      # @return [Array<Hyrax::FileMetadata>] or empty array if there are no ids or none of the ids map to Hyrax::FileMetadata
      # NOTE: Ignores non-existent ids and ids for non-file metadata resources.
      def find_many_file_metadata_by_ids(ids:)
        results = query_service.find_many_by_ids(ids: ids)
        results.select { |resource| resource.is_a? Hyrax::FileMetadata }
      end
    end
  end
end
