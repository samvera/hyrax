# frozen_string_literal: true
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
      def initialize(file_set, relation, user, use_valkyrie: Hyrax.config.query_index_from_valkyrie)
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
        use_valkyrie ? perform_ingest_file_through_valkyrie(io) : perform_ingest_file_through_active_fedora(io)
      end

      # Reverts file and spawns async job to characterize and create derivatives.
      # @param [String] revision_id
      # @return [CharacterizeJob, FalseClass] spawned job on success, false on failure
      def revert_to(revision_id)
        repository_file = related_file
        repository_file.restore_version(revision_id)
        return false unless file_set.save
        create_version(repository_file, user)
        CharacterizeJob.perform_later(file_set, repository_file.id)
      end

      # @note FileSet comparison is limited to IDs, but this should be sufficient, given that
      #   most operations here are on the other side of async retrieval in Jobs (based solely on ID).
      def ==(other)
        return false unless other.is_a?(self.class)
        file_set.id == other.file_set.id && relation == other.relation && user == other.user
      end

      private

      ##
      # Wraps the verisoning service with erro handling. if the service's
      # create handler isn't implemented, we want to accept that quietly here.
      def create_version(content, user)
        Hyrax::VersioningService.create(content, user)
      rescue NotImplementedError
        :no_op
      end

      ##
      # @return [Hydra::PCDM::File] the file referenced by relation
      def related_file
        file_set.public_send(normalize_relation(relation)) || raise("No #{relation} returned for FileSet #{file_set.id}")
      end

      def perform_ingest_file_through_active_fedora(io)
        # Skip versioning because versions will be minted by VersionCommitter as necessary during save_characterize_and_record_committer.
        Hydra::Works::AddFileToFileSet.call(file_set,
                                            io,
                                            relation,
                                            versioning: false)
        return false unless file_set.save
        repository_file = related_file
        create_version(repository_file, user)
        CharacterizeJob.perform_later(file_set, repository_file.id, pathhint(io))
      end

      def perform_ingest_file_through_valkyrie(io) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        Deprecation.warn "FileActor support for Valkyrie was experimental and " \
                         "is slated to be removed in favor of WorkUploadsHandler."
        file =
          begin
            Hyrax.storage_adapter.upload(resource: file_set, file: io, original_filename: io.original_name, use: relation)
          rescue StandardError => err
            Rails.logger.error("Failed to save file_metadata through valkyrie: #{err.message}")
            return false
          end
        file_metadata = Hyrax.custom_queries.find_file_metadata_by(id: file.id)
        create_version(file_metadata, user)

        file_set.file_ids << file_metadata.id
        file_set.original_file_id = file_metadata.id
        Hyrax.persister.save(resource: file_set)
        Hyrax.publisher.publish('object.metadata.updated', object: file_set, user: user)
        CharacterizeJob.perform_later(file_set, file_metadata.id.to_s, pathhint(io))
        file_metadata
      end

      def normalize_relation(relation)
        use_valkyrie ? normalize_relation_for_valkyrie(relation) : normalize_relation_for_active_fedora(relation)
      end

      def normalize_relation_for_active_fedora(relation)
        return relation.to_sym if relation.respond_to? :to_sym

        case relation
        when Hyrax::FileMetadata::Use::ORIGINAL_FILE
          :original_file
        when Hyrax::FileMetadata::Use::EXTRACTED_TEXT
          :extracted_file
        when Hyrax::FileMetadata::Use::THUMBNAIL
          :thumbnail_file
        else
          :original_file
        end
      end

      ##
      # @return [RDF::URI]
      def normalize_relation_for_valkyrie(relation)
        return relation if relation.is_a?(RDF::URI)

        Hyrax::FileMetadata::Use.uri_for(use: relation.to_sym)
      rescue ArgumentError
        Hyrax::FileMetadata::Use::ORIGINAL_FILE
      end

      def pathhint(io)
        io.uploaded_file&.uploader&.path || io.path
      end
    end
  end
end
