module Hyrax
  module Actors
    # actions for a file identified by file_set and relation (maps to use predicate)
    class FileActor
      attr_reader :file_set, :relation, :user

      # @param [FileSet] file_set the parent FileSet
      # @param [Symbol, #to_sym] relation the type/use for the file
      # @param [User] user the user to record as the Agent acting upon the file
      def initialize(file_set, relation, user)
        @file_set = file_set
        @relation = relation.to_sym
        @user = user
      end

      # Persists file as part of file_set and spawns a job to characterize and create derivatives.
      # @param [Hydra::Derivatives::IoDecorator] io the file to save in the repository, with mime_type and original_name
      # @return [Boolean] true on success (note: does NOT mean spawned job completed), false otherwise
      # @example for File
      #   file_actor = Hyrax::Actors::FileActor.new(fileset, :original_file, user)
      #   file = File.open('/tmp/mydir/upload.jpg', 'rb')
      #   io = Hydra::Derivatives::IoDecorator.new(file, 'image/jpeg', 'spirostomum_2400x1200.jpg')
      #   file_actor.ingest_file(io)
      # @example for Tempfile
      #   tempfile = get_tempfile_from_request # presume you get a Tempfile from Rack, Rails or wherever
      #   io = Hydra::Derivatives::IoDecorator.new(tempfile, 'image/jpeg', File.basename(tempfile.path))
      #   file_actor.ingest_file(io)
      # @example for ActionDispatch::Http::UploadedFile
      #   file = ActionDispatch::Http::UploadedFile.new(filename: '汉字.jpg', type: 'image/jpeg', tempfile: tempfile)
      #   io = Hydra::Derivatives::IoDecorator.new(file, file.content_type, file.original_filename)
      #   file_actor.ingest_file(io)
      # @note the primary requirement of the file passed to Hydra::Derivatives::IoDecorator is to support #read
      # @todo create a job to monitor the temp directory (or in a multi-worker system, directories!) to prune old files that have made it into the repo
      def ingest_file(io)
        # Skip versioning because versions will be minted by VersionCommitter as necessary during save_characterize_and_record_committer.
        Hydra::Works::AddFileToFileSet.call(file_set,
                                            io,
                                            relation,
                                            versioning: false)
        return false unless file_set.save
        repository_file = related_file
        Hyrax::VersioningService.create(repository_file, user)
        CharacterizeJob.perform_later(file_set, repository_file.id, path_for(io)) # path hint in case next worker is on same filesystem
        true
      end

      # Reverts file and spawns a job to characterize and create derivatives.
      # @param [String] revision_id
      # @return [Boolean] true on success (note: does NOT mean spawned job completed), false otherwise
      def revert_to(revision_id)
        repository_file = related_file
        repository_file.restore_version(revision_id)
        return false unless file_set.save
        Hyrax::VersioningService.create(repository_file, user)
        CharacterizeJob.perform_later(file_set, repository_file.id)
        true
      end

      def ==(other)
        return false unless other.is_a?(self.class)
        file_set == other.file_set && relation == other.relation && user == other.user
      end

      private

        # @return [Hydra::PCDM::File] the file referenced by relation
        def related_file
          file_set.public_send(relation) || raise("No #{relation} returned for FileSet #{file_set.id}")
        end

        # @param [Hydra::Derivatives::IoDecorator] io
        # @return [String] path (nil if unavailable)
        def path_for(io)
          io.path if io.respond_to?(:path) # e.g. ActionDispatch::Http::UploadedFile, CarrierWave::SanitizedFile, Tempfile, File
        end
    end
  end
end
