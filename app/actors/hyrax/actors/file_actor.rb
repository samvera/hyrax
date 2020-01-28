require 'wings/services/file_metadata_builder'

module Hyrax
  module Actors
    # Actions for a file identified by file_set and relation (maps to use predicate)
    # @note Spawns asynchronous jobs
    class FileActor
      attr_reader :file_set, :relation, :user, :use_valkyrie

      # @param [FileSet] file_set the parent FileSet
      # @param [Symbol, #to_sym] relation the type/use for the file
      # @param [User] user the user to record as the Agent acting upon the file
      def initialize(file_set, relation, user, use_valkyrie: false)
        @use_valkyrie = use_valkyrie
        @file_set = file_set
        @relation = normalize_relation(relation)
        @user = user
      end

      # Persists file as part of file_set and spawns async job to characterize and create derivatives.
      # @param [JobIoWrapper] io the file to save in the repository, with mime_type and original_name
      # @return [CharacterizeJob, FalseClass] spawned job on success, false on failure
      # @note Instead of calling this method, use IngestJob to avoid synchronous execution cost
      # @see IngestJob
      # @todo create a job to monitor the temp directory (or in a multi-worker system, directories!) to prune old files that have made it into the repo
      def ingest_file(io)
        perform_ingest_file(io)
      end

      # Reverts file and spawns async job to characterize and create derivatives.
      # @param [String] revision_id
      # @return [CharacterizeJob, FalseClass] spawned job on success, false on failure
      def revert_to(revision_id)
        repository_file = related_file
        repository_file.restore_version(revision_id)
        return false unless file_set.save
        Hyrax::VersioningService.create(repository_file, user)
        CharacterizeJob.perform_later(file_set, repository_file.id)
      end

      # @note FileSet comparison is limited to IDs, but this should be sufficient, given that
      #   most operations here are on the other side of async retrieval in Jobs (based solely on ID).
      def ==(other)
        return false unless other.is_a?(self.class)
        file_set.id == other.file_set.id && relation == other.relation && user == other.user
      end

      private

        # @return [Hydra::PCDM::File] the file referenced by relation
        def related_file
          file_set.public_send(normalize_relation(relation)) || raise("No #{relation} returned for FileSet #{file_set.id}")
        end

        # Persists file as part of file_set and records a new version.
        # Also spawns an async job to characterize and create derivatives.
        # @param [JobIoWrapper] io the file to save in the repository, with mime_type and original_name
        # @return [FileMetadata, FalseClass] the created file metadata on success, false on failure
        # @todo create a job to monitor the temp directory (or in a multi-worker system, directories!) to prune old files that have made it into the repo
        def perform_ingest_file(io)
          use_valkyrie ? perform_ingest_file_through_valkyrie(io) : perform_ingest_file_through_active_fedora(io)
        end

        def perform_ingest_file_through_active_fedora(io)
          # Skip versioning because versions will be minted by VersionCommitter as necessary during save_characterize_and_record_committer.
          Hydra::Works::AddFileToFileSet.call(file_set,
                                              io,
                                              relation,
                                              versioning: false)
          return false unless file_set.save
          repository_file = related_file
          Hyrax::VersioningService.create(repository_file, user)
          pathhint = io.uploaded_file.uploader.path if io.uploaded_file # in case next worker is on same filesystem
          CharacterizeJob.perform_later(file_set, repository_file.id, pathhint || io.path)
        end

        def perform_ingest_file_through_valkyrie(io)
          # Skip versioning because versions will be minted by VersionCommitter as necessary during save_characterize_and_record_committer.
          unsaved_file_metadata = io.to_file_metadata
          unsaved_file_metadata.type = [relation]
          begin
            saved_file_metadata = file_metadata_builder.create(io_wrapper: io, file_metadata: unsaved_file_metadata, file_set: file_set)
          rescue StandardError => e # Handle error persisting file metadata
            Rails.logger.error("Failed to save file_metadata through valkyrie: #{e.message}")
            return false
          end
          Hyrax::VersioningService.create(saved_file_metadata, user)
          pathhint = io.uploaded_file.uploader.path if io.uploaded_file # in case next worker is on same filesystem
          id = Hyrax.config.translate_uri_to_id.call saved_file_metadata.file_identifiers.first
          CharacterizeJob.perform_later(file_set, id, pathhint || io.path)
        end

        def file_metadata_builder
          Wings::FileMetadataBuilder.new(storage_adapter: Hyrax.storage_adapter,
                                         persister:       Hyrax.persister)
        end

        def normalize_relation(relation)
          use_valkyrie ? normalize_relation_for_valkyrie(relation) : normalize_relation_for_active_fedora(relation)
        end

        def normalize_relation_for_active_fedora(relation)
          return relation if relation.is_a? Symbol
          return relation.to_sym if relation.respond_to? :to_sym

          # TODO: whereever these are set, they should use FileSet.*_use... making the casecmp unnecessary
          return :original_file if relation.to_s.casecmp(Hyrax::FileSet::ORIGINAL_FILE_USE.to_s)
          return :extracted_file if relation.to_s.casecmp(Hyrax::FileSet::EXTRACTED_TEXT_USE.to_s)
          return :thumbnail_file if relation.to_s.casecmp(Hyrax::FileSet::THUMBNAIL_USE.to_s)
          :original_file
        end

        def normalize_relation_for_valkyrie(relation)
          # TODO: When this is fully switched to valkyrie, this should probably be removed and relation should always be passed
          #       in as a valid URI already set to the file's use
          case relation.to_s.to_sym
          when :original_file
            Hyrax::FileSet::ORIGINAL_FILE_USE
          when :extracted_file
            Hyrax::FileSet.EXTRACTED_TEXT_USE
          when :thumbnail_file
            Hyrax::FileSet::THUMBNAIL_USE
          else
            Hyrax::FileSet::ORIGINAL_FILE_USE
          end
        end
    end
  end
end
