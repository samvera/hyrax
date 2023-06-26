# frozen_string_literal: true
module Hyrax
  # @deprecated Use JobIoWrapper instead
  class WorkingDirectory
    class << self
      # @deprecated No longer used anywhere in Hyrax code, naively assumes filenames of versions/revisions are distinct
      # Returns the file passed as filepath if that file exists. Otherwise it grabs the file from repository,
      # puts it on the disk and returns that path.
      # @param [String] repository_file_id identifier for Hydra::PCDM::File
      # @param [String] id the identifier of the FileSet
      # @param [String, NilClass] filepath path to existing cached copy of the file
      # @return [String] path of the working file
      def find_or_retrieve(repository_file_id, id, filepath = nil)
        Deprecation.warn("Hyrax::WorkingDirectory.find_or_retrieve() is deprecated and no longer used in Hyrax")
        return filepath if filepath && File.exist?(filepath)
        repository_file = Hydra::PCDM::File.find(repository_file_id)
        working_path = full_filename(id, repository_file.original_name)
        if File.exist?(working_path)
          Hyrax.logger.debug "#{repository_file.original_name} already exists in the working directory at #{working_path}"
          return working_path
        end
        copy_repository_resource_to_working_directory(repository_file, id)
      end

      # @param [#original_name, #id] file the resource in the repo
      # @param [String] id the identifier of the FileSet
      # @return [String] path of the working file
      def copy_repository_resource_to_working_directory(file, id)
        Hyrax.logger.debug "Loading #{file.original_name} (#{file.id}) from the repository to the working directory"
        copy_stream_to_working_directory(id, file.original_name, StringIO.new(file.content))
      end

      private

      # @param [String] id the identifier
      # @param [String] name the file name
      # @param [#read] stream the stream to copy to the working directory
      # @return [String] path of the working file
      def copy_stream_to_working_directory(id, name, stream)
        working_path = full_filename(id, name)
        Hyrax.logger.debug "Writing #{name} to the working directory at #{working_path}"
        FileUtils.mkdir_p(File.dirname(working_path))
        IO.copy_stream(stream, working_path)
        working_path
      end

      def full_filename(id, original_name)
        pair = id.scan(/..?/).first(4).push(id)
        File.join(Hyrax.config.working_path, *pair, original_name)
      end
    end
  end
end
