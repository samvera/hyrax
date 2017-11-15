# frozen_string_literal: true

module Hyrax
  # Stores a file and an associated FileNode
  class FileNodeBuilder
    attr_reader :storage_adapter, :persister
    def initialize(storage_adapter:, persister:)
      @storage_adapter = storage_adapter
      @persister = persister
    end

    # @param file [ActionDispatch::Http::UploadedFile]
    # @param node [FileNode] the metadata to represent the file
    # @param file_set [FileNode] the associated FileSet
    # @return [FileNode] the persisted metadata node that represents the file
    def create(file:, node:, file_set:)
      # TODO: modify the storage_adapter to record:
      #    VersionCommitter.create(version_id: version.uri, committer_login: user_key)
      stored_file = storage_adapter.upload(file: file,
                                           original_filename: node.original_filename.first,
                                           resource: node)
      node.file_identifiers = node.file_identifiers + [stored_file.id]
      saved_node = persister.save(resource: node)
      file_set.member_ids += [saved_node.id]
      file_set = persister.save(resource: file_set)
      CharacterizeJob.perform_later(file_set.id.to_s)
      # note the returned saved_node does not yet contain the characterization done in the async job
      saved_node
    end
  end
end
