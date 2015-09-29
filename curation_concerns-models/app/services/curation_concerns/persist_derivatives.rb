module CurationConcerns
  class PersistDerivatives < Hydra::Derivatives::PersistOutputFileService
    # Persists a derivative to the local file system.
    # This Service conforms to the signature of `Hydra::Derivatives::PersistOutputFileService`.
    # This service is an alternative to the default Hydra::Derivatives::PersistOutputFileService.
    # This service will always update existing and does not do versioning of persisted files.
    #
    # @param [#read] stream the derivative filestream
    # @param [Hash] directives
    # @option directives [String] :url a url to the file destination
    def self.call(stream, directives)
      output_file(directives) do |output|
        IO.copy_stream(stream, output)
      end
    end

    # Open the output file to write and yield the block to the
    # file. It makes the directories in the path if necessary.
    def self.output_file(directives, &blk)
      # name = derivative_path_factory.derivative_path_for_reference(object, destination_name)
      raise ArgumentError, "No :url was provided in the transcoding directives" unless directives.key?(:url)
      uri = URI(directives.fetch(:url))
      raise ArgumentError, "Must provide a file uri" unless uri.scheme == 'file'
      output_file_dir = File.dirname(uri.path)
      FileUtils.mkdir_p(output_file_dir) unless File.directory?(output_file_dir)
      File.open(uri.path, 'wb', &blk)
    end

    def self.derivative_path_factory
      DerivativePath
    end
  end
end
