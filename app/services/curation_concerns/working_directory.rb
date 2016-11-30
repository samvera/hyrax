module CurationConcerns
  class WorkingDirectory
    class << self
      # @param [String] repository_file_id identifier for Hydra::PCDM::File
      # @param [String] id the identifier of the FileSet
      # @param [String, NilClass] filepath path to existing cached copy of the file
      # @return [String] path of the working file
      def find_or_retrieve(repository_file_id, id, filepath = nil)
        return filepath if filepath && File.exist?(filepath)
        repository_file = Hydra::PCDM::File.find(repository_file_id)
        working_path = full_filename(id, repository_file.original_name)
        if File.exist?(working_path)
          Rails.logger.debug "#{repository_file.original_name} already exists in the working directory at #{working_path}"
          return working_path
        end
        copy_repository_resource_to_working_directory(repository_file, id)
      end

      # @param [File, ActionDispatch::Http::UploadedFile] file
      # @param [String] id the identifier of the FileSet
      # @return [String] path of the working file
      def copy_file_to_working_directory(file, id)
        file_name = file.respond_to?(:original_filename) ? file.original_filename : ::File.basename(file)
        copy_stream_to_working_directory(id, file_name, file)
      end

      # @param [ActiveFedora::File] file the resource in the repo
      # @param [String] id the identifier of the FileSet
      # @return [String] path of the working file
      def copy_repository_resource_to_working_directory(file, id)
        Rails.logger.debug "Loading #{file.original_name} (#{file.id}) from the repository to the working directory"
        # TODO: this causes a load into memory, which we'd like to avoid
        copy_stream_to_working_directory(id, file.original_name, StringIO.new(file.content))
      end

      private

        # @param [String] id the identifier
        # @param [String] name the file name
        # @param [#read] stream the stream to copy to the working directory
        # @return [String] path of the working file
        def copy_stream_to_working_directory(id, name, stream)
          working_path = full_filename(id, name)
          Rails.logger.debug "Writing #{name} to the working directory at #{working_path}"
          FileUtils.mkdir_p(File.dirname(working_path))
          IO.copy_stream(stream, working_path)
          working_path
        end

        def full_filename(id, original_name)
          pair = id.scan(/..?/).first(4).push(id)
          File.join(CurationConcerns.config.working_path, *pair, original_name)
        end
    end
  end
end
