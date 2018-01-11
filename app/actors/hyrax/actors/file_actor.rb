module Hyrax
  module Actors
    # Actions for a file identified by file_set and relation (maps to use predicate)
    # @note Spawns asynchronous jobs
    class FileActor
      attr_reader :file_set, :relation, :user

      # @param [FileSet] file_set the parent FileSet
      # @param [RDF::URI] relation the type/use for the file
      # @param [User] user the user to record as the Agent acting upon the file
      def initialize(file_set, relation, user)
        @file_set = file_set
        @relation = relation
        @user = user
      end

      # Persists file as part of file_set and spawns async job to characterize and create derivatives.
      # @param [JobIoWrapper] io the file to save in the repository, with mime_type and original_name
      # @return [FileNode, FalseClass] the created file node on success, false on failure
      # @note Instead of calling this method, use IngestJob to avoid synchronous execution cost
      # @see IngestJob
      # @todo create a job to monitor the temp directory (or in a multi-worker system, directories!) to prune old files that have made it into the repo
      def ingest_file(io)
        # Skip versioning because versions will be minted by VersionCommitter as necessary during save_characterize_and_record_committer.
        storage_adapter = Valkyrie::StorageAdapter.find(:disk)
        persister = Valkyrie::MetadataAdapter.find(:indexing_persister).persister
        node_builder = Hyrax::FileNodeBuilder.new(storage_adapter: storage_adapter,
                                                  persister: persister)
        unsaved_node = io.to_file_node
        unsaved_node.use = relation
        begin
          saved_node = node_builder.create(file: io.file, node: unsaved_node, file_set: file_set)
        rescue StandardError # Handle error persisting file node
          return false
        end
        Hyrax::VersioningService.create(saved_node, user)
        saved_node
      end

      # Reverts file and spawns async job to characterize and create derivatives.
      # @param [String] revision_id
      # @return [FileNode, FalseClass] reverted file node on success, false on failure
      def revert_to(revision_id)
        persister = Valkyrie::MetadataAdapter.find(:indexing_persister).persister
        repository_file = related_file
        repository_file.restore_version(revision_id)
        return false unless persister.save(resource: file_set)
        Hyrax::VersioningService.create(repository_file, user)
        CharacterizeJob.perform_later(repository_file.id.to_s)
        repository_file
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
          file_set.member_by(use: relation) || raise("No #{relation} returned for FileSet #{file_set.id}")
        end
    end
  end
end
