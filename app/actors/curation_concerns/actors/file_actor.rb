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
        working_file = WorkingDirectory.copy_file_to_working_directory(file, file_set.id)
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
        working_file = WorkingDirectory.copy_repository_resource_to_working_directory(repository_file, file_set.id)
        CharacterizeJob.perform_later(file_set, working_file)
        true
      end
    end
  end
end
