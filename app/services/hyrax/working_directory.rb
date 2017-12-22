module Hyrax
  # @deprecated Use JobIoWrapper instead
  class WorkingDirectory
    class << self
      # Returns the file passed as filepath if that file exists. Otherwise it grabs the file from repository,
      # puts it on the disk and returns that path.
      # @param [String] repository_file_id identifier for Hyrax::FileNode
      # @param [String] id the identifier of the FileSet
      # @param [String, NilClass] filepath path to existing cached copy of the file
      # @return [String] path of the working file
      def find_or_retrieve(repository_file_id, id, filepath = nil)
        return filepath if filepath && File.exist?(filepath)
        file_node = Hyrax::Queries.find_by(id: Valkyrie::ID.new(repository_file_id))
        if File.exist?(file_node.file.disk_path)
          Rails.logger.debug "#{file_node.file.disk_path} already exists in the working path."
          return file_node.file.disk_path
        end
        copy_repository_resource_to_working_directory(file_node.file, id)
      end

      # @param [Valkyrie::StorageAdapter::File] file the resource in the repo
      # @param [String] id the identifier of the FileSet
      # @return [String] path of the working file
      def copy_repository_resource_to_working_directory(file, id)
        Rails.logger.debug "Loading #{file.original_name} (#{file.id}) from the repository to the working directory"
        name = File.basename(file.disk_path)
        working_path = full_filename(id, name)
        Rails.logger.debug "Writing #{name} to the working directory at #{working_path}"
        FileUtils.mkdir_p(File.dirname(working_path))
        IO.copy_stream(file, working_path)
        working_path
      end

      private

        # @param [String] id the identifier
        # @param [String] name the file name
        # @param [#read] stream the stream to copy to the working directory
        # @return [String] path of the working file
        def copy_stream_to_working_directory(id, name, stream)
          working_path = g(id, name)
          Rails.logger.debug "Writing #{name} to the working directory at #{working_path}"
          FileUtils.mkdir_p(File.dirname(working_path))
          IO.copy_stream(stream, working_path)
          working_path
        end

        # @return [String] a filename for a locally cached copy of the file
        def full_filename(id, original_name)
          pair = id.to_s.scan(/..?/).first(4).push(id)
          File.join(Hyrax.config.working_path, *pair, original_name)
        end
    end
  end
end
