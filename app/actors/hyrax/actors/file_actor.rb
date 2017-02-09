module Hyrax
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
      # @param [Boolean] asynchronous set to true if you want to launch a new background job.
      def ingest_file(file, asynchronous)
        method = if asynchronous
                   :perform_later
                 else
                   :perform_now
                 end

        IngestFileJob.send(method,
                           file_set,
                           working_file(file),
                           user,
                           ingest_options(file))
        true
      end

      def revert_to(revision_id)
        repository_file = file_set.send(relation.to_sym)
        repository_file.restore_version(revision_id)

        return false unless file_set.save

        Hyrax::VersioningService.create(repository_file, user)

        # Characterize the original file from the repository
        CharacterizeJob.perform_later(file_set, repository_file.id)
        true
      end

      private

        def working_file(file)
          path = file.path
          return path if File.exist?(path)
          Hyrax::WorkingDirectory.copy_file_to_working_directory(file, file_set.id)
        end

        def ingest_options(file, opts = {})
          opts[:mime_type] = file.content_type if file.respond_to?(:content_type)
          opts[:filename] = file.original_filename if file.respond_to?(:original_filename)
          opts.merge!(relation: relation)
        end
    end
  end
end
