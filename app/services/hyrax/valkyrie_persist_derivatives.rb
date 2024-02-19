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
    def self.call(stream,
                  directives,
                  uploader: Hyrax::ValkyrieUpload.new(storage_adapter: Hyrax.config.derivatives_storage_adapter))
      file_set = fileset_for_directives(directives)

      # Valkyrie storage adapters will typically expect an IO-like object that
      # responds to #rewind and #read so we have created a StringIO
      tmpfile = Tempfile.new(file_set.id, encoding: 'ascii-8bit')
      stream = StringIO.new(stream) if stream.is_a?(String)
      stream.rewind
      output = tmpfile.write(stream.read)
      tmpfile.flush
      raise 'blank file detected' if output.zero?

      filename = filename(directives)
      Hyrax.logger.debug "Uploading derivative for FileSet #{file_set.id} as #{filename}"
      uploader.upload(io: tmpfile, filename: filename, file_set: file_set, use: file_metadata(directives), mime_type: directives[:mime_type])
    end

    # The filepath will look something like
    # /app/samvera/hyrax-webapp/derivatives/95/93/tv/12/3-thumbnail.jpeg and
    # we want to extract the FileSet id, which in this case would be 9593tv123
    #
    # @param [String] path
    # @return [Hyrax::FileSet]
    def self.fileset_for_directives(directives)
      path = URI(directives.fetch(:url)).path
      # checks if it's a file path, else assuming it is already an id
      # Hyrax::FileSetDerivativesService#extract_full_text passes in the raw uri
      # and not a derivative_url like the other derivative formats
      id = if path.include?("/")
             path.sub(Hyrax.config.derivatives_path.to_s, "")
                 .delete('/')
                 .match(/^(.*)-\w*(\.\w+)*$/) { |m| m[1] }
           else
             path
           end
      raise "Could not extract fileset id from path #{path}" unless id

      Hyrax.metadata_adapter.query_service.find_by(id: id)
    end

    def self.filename(directives)
      URI(directives.fetch(:url)).path.split('/').last
    end

    def self.file_metadata(directives)
      if directives.key?(:container)
        "Hyrax::FileMetadata::Use::#{directives[:container].upcase}".constantize
      else
        Hyrax::FileMetadata::Use::THUMBNAIL_IMAGE
      end
    end
  end
end
