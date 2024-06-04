# frozen_string_literal: true
module Wings
  module CustomQueries
    # Custom query override specific to Wings for finding Hydra::PCDM::File and converting to Hyrax::FileMetadata.
    #
    # @example
    #   Hyrax.custom_queries.find_file_metadata_by(id: valkyrie_id, use_valkyrie: true)
    #   Hyrax.custom_queries.find_file_metadata_by_alternate_identifier(alternate_identifier: id, use_valkyrie: true)
    class FindFileMetadata
      def self.queries
        [:find_file_metadata_by,
         :find_file_metadata_by_alternate_identifier,
         :find_many_file_metadata_by_ids,
         :find_many_file_metadata_by_use]
      end

      def initialize(query_service:)
        @query_service = query_service
      end

      attr_reader :query_service
      delegate :resource_factory, to: :query_service

      ##
      # Find a Hyrax::FileMetadata using a Valkyrie ID,
      #
      # @param id [Valkyrie::ID, String]
      # @param use_valkyrie [boolean] defaults to true; optionally return
      #   ActiveFedora::File objects if false
      #
      # @return [Hyrax::FileMetadata, Hydra::PCDM::File] - when use_valkyrie is
      #   true, returns FileMetadata resource; otherwise, returns ActiveFedora PCDM::File
      #
      # @raise [Hyrax::ObjectNotFoundError]
      def find_file_metadata_by(id:, use_valkyrie: true)
        fcrepo_flag =
          begin
            ::Valkyrie::StorageAdapter.adapter_for(id: id).is_a?(::Valkyrie::Storage::Fedora)
          rescue ::Valkyrie::StorageAdapter::AdapterNotFoundError
            true # assume fcrepo if we can't find an adapter
          end

        if fcrepo_flag
          find_file_metadata_by_alternate_identifier(alternate_identifier: id, use_valkyrie: use_valkyrie)
        else
          result = ActiveFedora::Base.where(file_identifier_ssim: id.to_s).first ||
                   raise(Hyrax::ObjectNotFoundError)
          result.valkyrie_resource
        end
      end

      # Find a Hyrax::FileMetadata using an alternate ID, and map it to a
      #
      #
      # @param alternate_identifier [Valkyrie::ID, String]
      # @param use_valkyrie [boolean] defaults to true; optionally return
      #   ActiveFedora::File objects if false
      #
      # @return [Hyrax::FileMetadata, Hydra::PCDM::File] - when use_valkyrie is
      #   true, returns FileMetadata resource; otherwise, returns ActiveFedora PCDM::File
      #
      # @raise [Hyrax::ObjectNotFoundError]
      def find_file_metadata_by_alternate_identifier(alternate_identifier:, use_valkyrie: true)
        alternate_identifier = ::Valkyrie::ID.new(alternate_identifier).to_s
        object = Hydra::PCDM::File.find(alternate_identifier)
        raise Hyrax::ObjectNotFoundError if object.new_record? || object.empty?

        if use_valkyrie == false
          warn_about_deprecation
          return object
        end

        object.valkyrie_resource
      end

      # Find an array of file metadata using Valkyrie IDs, and map them to
      # Hyrax::FileMetadata maintaining order based on given ids.
      #
      # @note Ignores non-existent ids and ids for non-file metadata resources.
      #
      # @param ids [Array<Valkyrie::ID, String>]
      # @param use_valkyrie [boolean] defaults to true; optionally return
      #   ActiveFedora::File objects if false
      #
      # @return [Array<Hyrax::FileMetadata, Hydra::PCDM::File>] or empty array
      #   if there are no ids or none of the ids map to Hyrax::FileMetadata
      def find_many_file_metadata_by_ids(ids:, use_valkyrie: true)
        ids.each_with_object([]) do |alt_id, results|
          results << find_file_metadata_by_alternate_identifier(alternate_identifier: alt_id, use_valkyrie: use_valkyrie)
        rescue Hyrax::ObjectNotFoundError
          next
        end
      end

      ##
      # Find file metadata for files within a resource that have the requested
      # use.
      #
      # @param use [RDF::URI] uri for the desired use Type
      # @param use_valkyrie [boolean] defaults to true; optionally return
      #   ActiveFedora::File objects if false
      #
      # @return [Array<Hyrax::FileMetadata, Hydra::PCDM::File>] or empty array
      #   if there are no files with the requested use
      #
      # @example
      #   Hyrax.query_service.find_file_metadata_by_use(use: ::RDF::URI("http://pcdm.org/ExtractedText"))
      #
      def find_many_file_metadata_by_use(resource:, use:, use_valkyrie: true)
        pcdm_files = find_many_file_metadata_by_ids(ids: resource.file_ids, use_valkyrie: false)
        pcdm_files.select! { |pcdm_file| !pcdm_file.empty? && pcdm_file.metadata_node.type.include?(use) }

        if use_valkyrie == false
          warn_about_deprecation
          return pcdm_files
        end

        pcdm_files.map(&:valkyrie_resource)
      end

      private

      def warn_about_deprecation
        Deprecation.warn("use_valkyrie: is deprecated for valkyrie/wings queries")
      end
    end
  end
end
