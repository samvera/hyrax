module CurationConcerns
  class PersistDerivatives < Hydra::Derivatives::PersistOutputFileService
    # Persists a derivative to the local file system.
    # This Service conforms to the signature of `Hydra::Derivatives::PersistOutputFileService`.
    # This service is an alternative to the default Hydra::Derivatives::PersistOutputFileService.
    # This service will always update existing and does not do versioning of persisted files.
    #
    # @param [Hydra::Works::GenericFile::Base] object the file will be added to
    # @param [Hydra::Derivatives::IoDecorator] file the derivative filestream
    # @param [String] extract file type (e.g. 'thumbnail') from Hydra::Derivatives created destination_name
    #
    def self.call(object, file, destination_name)
      output_file(object, destination_name) do |output|
        while buffer = file.read(4096)
          output.write buffer
        end
      end
    end

    # Open the output file to write and yield the block to the
    # file.  It will make the directories in the path if
    # necessary.
    def self.output_file(object, destination_name, &blk)
      name = derivative_path_factory.derivative_path_for_reference(object, destination_name)
      output_file_dir = File.dirname(name)
      FileUtils.mkdir_p(output_file_dir) unless File.directory?(output_file_dir)
      File.open(name, 'wb', &blk)
    end

    def self.derivative_path_factory
      DerivativePath
    end
  end
end
