# frozen_string_literals: true

module Hyrax
  # Responsible for handling attaching files to a FileSet as well as metadata
  class FileSetChangeSetPersister < ChangeSetPersister
    after_save :ingest_file
    after_save :save_notification
    after_delete :send_delete_notification
    class_attribute :node_builder
    self.node_builder = Hyrax::FileNodeBuilder.new(
      storage_adapter: Valkyrie::StorageAdapter.find(:disk),
      persister: Valkyrie::MetadataAdapter.find(:indexing_persister).persister
    )

    private

      def send_delete_notification(change_set:)
        Hyrax.config.callback.run(:after_destroy, change_set.resource.id, change_set.user)
      end

      def save_notification(change_set:, resource:)
        return if change_set.respond_to?(:files) # This is an update metadata action
        Hyrax.config.callback.run(:after_update_metadata, resource, change_set.user)
      end

      # Upload the files if this is the upload change set.
      # @param change_set [FileUploadChangeSet, FileSetChangeSet]
      # @param resource [FileSet]
      def ingest_file(change_set:, resource:, use: Valkyrie::Vocab::PCDMUse.OriginalFile)
        return unless change_set.respond_to?(:files) # This is a create/update files
        attach_uploaded_file(file: change_set.files.first, file_set: resource, use: use)
        ContentNewVersionEventJob.perform_later(resource, change_set.user)
      end

      def attach_uploaded_file(file:, file_set:, use:)
        file_node = create_file_node(file: file, use: use)
        file_set.member_ids += [file_node.id]
        persister.save(resource: file_set)
        # TODO: Derivatives
      end

      # Creates a Hyrax::FileNode and stores the file.
      def create_file_node(file:, use:)
        original_name = file.original_filename
        node = Hyrax::FileNode.new(label: original_name,
                                   original_filename: original_name,
                                   mime_type: file.content_type,
                                   use: [use])
        # Characterization happens in the node builder
        node_builder.create(file: file, node: node)
      end
  end
end
