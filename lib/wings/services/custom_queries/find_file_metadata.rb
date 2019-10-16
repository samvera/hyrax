require 'wings/services/file_converter_service'
module Wings
  module CustomQueries
    class FindFileMetadata
      # Custom query override specific to Wings
      # Use:
      #   Hyrax.query_service.custom_queries.find_file_metadata_by(id: valkyrie_id, use_valkyrie: true)
      #   Hyrax.query_service.custom_queries.find_file_metadata_by_alternate_identifier(alternate_identifier: id, use_valkyrie: true)

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

      # WARNING: In general, prefer find_by_alternate_identifier over this
      # method.
      #
      # Hyrax uses a shortened noid in place of an id, and this is what is
      # stored in ActiveFedora, which is still the storage backend for Hyrax.
      #
      # If you do not heed this warning, then switch to Valyrie's Postgres
      # MetadataAdapter, but continue passing noids to find_by, you will
      # start getting ObjectNotFoundErrors instead of the objects you wanted
      #
      # Find a file metadata record using a Valkyrie ID, and map it to a FileMetadata Resource
      # @param id [Valkyrie::ID, String]
      # @param use_valkyrie [boolean] defaults to true; optionally return ActiveFedora::File objects if false
      # @return [FileMetadata]
      # @raise [Hyrax::ObjectNotFoundError]
      def find_file_metadata_by(id:, use_valkyrie: true)
        find_file_metadata_by_alternate_identifier(alternate_identifier: id, use_valkyrie: use_valkyrie)
      end

      # Find a file record using an alternate ID, and map it to a Valkyrie FileMetadata Resource
      # @param alternate_identifier [Valkyrie::ID, String]
      # @param use_valkyrie [boolean] defaults to true; optionally return ActiveFedora::File objects if false
      # @return [Valkyrie::Resource]
      # @raise [Hyrax::ObjectNotFoundError]
      def find_file_metadata_by_alternate_identifier(alternate_identifier:, use_valkyrie: true)
        alternate_identifier = ::Valkyrie::ID.new(alternate_identifier.to_s) if alternate_identifier.is_a?(String)
        raise Hyrax::ObjectNotFoundError unless Hydra::PCDM::File.exists?(alternate_identifier.to_s)
        object = Hydra::PCDM::File.find(alternate_identifier.to_s)
        return object if use_valkyrie == false
        Wings::FileConverterService.af_file_to_resource(af_file: object)
      end

      # Find an array of file metadata using Valkyrie IDs, and map them to Hyrax::FileMetadata maintaining order based on given ids
      # @param [Array<Valkyrie::ID, String>] ids
      # @return [Array<Hyrax::FileMetadata>] or empty array if there are no ids or none of the ids map to Hyrax::FileMetadata
      # NOTE: Ignores non-existent ids and ids for non-file metadata resources.
      def find_many_file_metadata_by_ids(ids:, use_valkyrie: true)
        results = []
        ids.each do |alt_id|
          begin
            # For Wings, the id and alt_id are the same, so just use alt id querying.
            file_metadata = query_service.custom_queries.find_file_metadata_by_alternate_identifier(alternate_identifier: alt_id, use_valkyrie: use_valkyrie)
            results << file_metadata
          rescue Hyrax::ObjectNotFoundError # ignores non-existent ids
            next
          end
        end
        results
      end
    end
  end
end
