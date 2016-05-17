module CurationConcerns
  module Actors
    # actions for a file identified by file_set and relation (maps to use predicate)
    class FileActor
      attr_reader :file_set, :relation, :user

      # @param [FileSet] file_set the parent FileSet
      # @param [String] relation the type/use for the file.
      # @param [User] user the user to record as the Agent acting upon the file
      def initialize(file_set, relation, user)
        @file_set = file_set
        @relation = relation
        @user = user
      end

      # Puts the uploaded content into a staging directory. Then kicks off a
      # job to ingest the file into the repository, then characterize and
      # create derivatives with this on disk variant.
      # TODO: create a job to monitor this directory and prune old files that
      # have made it to the repo
      # @param [File, ActionDigest::HTTP::UploadedFile, Tempfile] file the file to save in the repository
      def ingest_file(file)
        working_file = copy_file_to_working_directory(file, file_set.id)
        mime_type = file.respond_to?(:content_type) ? file.content_type : nil
        IngestFileJob.perform_later(file_set, working_file, mime_type, user, relation)
        true
      end

      def revert_to(revision_id)
        repository_file = file_set.send(relation.to_sym)
        repository_file.restore_version(revision_id)

        return false unless file_set.save

        CurationConcerns::VersioningService.create(repository_file, user)

        # Retrieve a copy of the original file from the repository
        working_file = copy_repository_resource_to_working_directory(repository_file)
        CharacterizeJob.perform_later(file_set, working_file)
        true
      end

      private

        # @param [File, ActionDispatch::Http::UploadedFile] file
        # @param [String] id the identifier of the FileSet
        # @return [String] path of the working file
        def copy_file_to_working_directory(file, id)
          file_name = file.respond_to?(:original_filename) ? file.original_filename : ::File.basename(file)
          copy_stream_to_working_directory(id, file_name, file)
        end

        # @param [ActiveFedora::File] file the resource in the repo
        # @return [String] path of the working file
        def copy_repository_resource_to_working_directory(file)
          copy_stream_to_working_directory(file_set.id, file.original_name, StringIO.new(file.content))
        end

        # @param [String] id the identifier
        # @param [String] name the file name
        # @param [#read] stream the stream to copy to the working directory
        # @return [String] path of the working file
        def copy_stream_to_working_directory(id, name, stream)
          working_path = full_filename(id, name)
          FileUtils.mkdir_p(File.dirname(working_path))
          IO.copy_stream(stream, working_path)
          working_path
        end

        def full_filename(id, original_name)
          pair = id.scan(/..?/).first(4)
          File.join(CurationConcerns.config.working_path, *pair, original_name)
        end
    end
  end
end
