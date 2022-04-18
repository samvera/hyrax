# frozen_string_literal: true
module Hyrax
  class ValkyriePersistDerivatives < Hydra::Derivatives::PersistOutputFileService
    # Persists a derivative using the defined Valkyrie storage adapter
    #
    # This Service conforms to the signature of `Hydra::Derivatives::PersistOutputFileService`.
    # This service is a Valkyrized alternative to the default Hydra::Derivatives::PersistOutputFileService.
    # This service will always update existing and does not do versioning of persisted files.
    #
    # to replace the default AF derivative pipeline, set
    #     ```
    #     Hydra::Derivatives.config.output_file_service = Hyrax::ValkyriePersistDerivatives
    #     Hydra::Derivatives.config.source_file_service = Hyrax::LocalFileService
    #     ```
    #
    # @param [#read] stream the derivative filestream
    # @param [Hash] directives
    # @option directives [String] :url a url to the file destination
    def self.call(stream, directives)
      filepath = URI(directives.fetch(:url)).path
      fileset_id = fileset_id_from_path(filepath)
      fileset = Hyrax.metadata_adapter.query_service.find_by(id: fileset_id)

      # Valkyrie storage adapters will typically expect an IO-like object that
      # responds to #path -- here we only have a StringIO, so some
      # transformation is in order
      tmpfile = Tempfile.new(fileset_id, encoding: 'ascii-8bit')
      tmpfile.write stream.read

      Rails.logger.debug "Uploading thumbnail for FileSet #{fileset_id} as #{filepath}"

      ::Hyrax::ValkyrieUpload.file(
        io: tmpfile,
        filename: filepath,
        file_set: fileset,
        use: Hyrax::FileMetadata::Use::THUMBNAIL,
        storage_adapter: Hyrax.config.derivatives_storage_adapter
      )
    end

    # The filepath will look something like
    # /app/samvera/hyrax-webapp/derivatives/95/93/tv/12/3-thumbnail.jpeg and
    # we want to extract the FileSet id, which in this case would be 9593tv123
    #
    # @param [String] path
    # @return [String]
    def self.fileset_id_from_path(path)
      path.sub(Hyrax.config.derivatives_path.to_s, "")
          .sub(/-[^\/]+\..*$/, "")
          .delete("/")
    end
  end
end
