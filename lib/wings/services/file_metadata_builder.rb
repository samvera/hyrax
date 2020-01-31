# frozen_string_literal: true
# TODO: The file_metadata resource and the file_metadata_builder should be in Hyrax as they will be needed for non-wings valkyrie implementations too.

module Wings
  # Stores a file and an associated Hyrax::FileMetadata
  class FileMetadataBuilder
    include Hyrax::Noid

    attr_reader :storage_adapter, :persister
    def initialize(storage_adapter:, persister:)
      @storage_adapter = storage_adapter
      @persister = persister
    end

    # @param io_wrapper [JobIOWrapper] with details about the uploaded file
    # @param file_metadata [Hyrax::FileMetadata] the metadata to represent the file
    # @param file_set [Valkyrie::Resouce, Hydra::Works::FileSet] the associated FileSet # TODO: WINGS - Remove Hydra::Works::FileSet as a potential type when valkyrization is complete.
    # @return [Hyrax::FileMetadata] the persisted metadata file_metadata that represents the file
    def create(io_wrapper:, file_metadata:, file_set:)
      io_wrapper = build_file(io_wrapper, file_metadata.type)
      file_set.save unless file_set.persisted?
      file_metadata.id = ::Valkyrie::ID.new(assign_id)
      file_metadata.file_set_id = file_set.id
      stored_file = storage_adapter.upload(file: io_wrapper,
                                           original_filename: io_wrapper.original_filename,
                                           content_type: io_wrapper.content_type,
                                           resource: file_metadata,
                                           resource_uri_transformer: Hyrax.config.resource_id_to_uri_transformer)
      file_metadata.file_identifiers = [stored_file.id]
      attach_file_metadata(file_metadata: file_metadata, file_set: file_set)
    end

    # @param file_metadata [Hyrax::FileMetadata] the metadata to represent the file
    # @param file_set [Valkyrie::Resouce, Hydra::Works::FileSet] the associated FileSet # TODO: WINGS - Remove Hydra::Works::FileSet as a potential type when valkyrization is complete.
    # @return [Hyrax::FileMetadata] the persisted metadata file_metadata that represents the file
    def attach_file_metadata(file_metadata:, file_set:)
      file_set.is_a?(::Valkyrie::Resource) ? attach_file_metadata_to_valkyrie_file_set(file_metadata, file_set) : file_metadata
    end

    private

      ##
      # @api private
      def attach_file_metadata_to_valkyrie_file_set(file_metadata, file_set)
        # This is for storage adapters other than wings.  The wings storage adapter already attached the file to the file_set.
        # This process is a no-op for wings.  # TODO: WINGS - May need to verify this is a no-op for wings once file_set is passed in as a resource.
        # TODO: WINGS - Need to test this against other adapters once they are available for use.
        existing_file_metadata = current_original_file(file_set) || file_metadata
        file_metadata = existing_file_metadata.new(file_metadata.to_h.except(:id))
        saved_file_metadata = persister.save(resource: file_metadata)
        file_set.file_ids = [saved_file_metadata.id]
        persister.save(resource: file_set)
        saved_file_metadata
      end

      ##
      # @api private
      # @return [Hyrax::FileMetadata, nil]
      def current_original_file(file_set)
        Hyrax.custom_queries.find_original_file(file_set: file_set)
      rescue ::Valkyrie::Persistence::ObjectNotFoundError
        nil
      end

      # Class for wrapping the file being ingested
      class IoDecorator < SimpleDelegator
        attr_reader :original_filename, :content_type, :length, :use, :tempfile

        # @param [IO] io stream for the file content
        # @param [String] original_filename
        # @param [String] content_type
        # @param [RDF::URI] use the URI for the PCDM predicate indicating the use for this resource
        def initialize(io, original_filename, content_type, content_length, use)
          @original_filename = original_filename
          @content_type = content_type
          @length = content_length
          @use = use
          @tempfile = io
          super(io)
        end
      end

      # Constructs the IoDecorator for ingesting the intermediate file
      # @param [JobIOWrapper] io wrapper with details about the uploaded file
      # @param [RDF::URI] use the URI for the PCDM predicate indicating the use for this resource
      def build_file(io_wrapper, use)
        IoDecorator.new(io_wrapper.file, io_wrapper.original_name, io_wrapper.mime_type, io_wrapper.size, use)
      end
  end
end
