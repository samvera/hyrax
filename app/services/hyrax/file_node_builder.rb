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
    # @return [FileNode] the persisted metadata node that represents the file
    def create(file:, node:)
      saved_node = persister.save(resource: node)
      # TODO: modify the storage_adapter to record:
      #    VersionCommitter.create(version_id: version.uri, committer_login: user_key)

      stored_file = storage_adapter.upload(file: file,
                                           original_filename: node.original_filename.first,
                                           resource: saved_node)
      saved_node.file_identifiers = saved_node.file_identifiers + [stored_file.id]
      saved_node = Valkyrie::FileCharacterizationService.for(file_node: saved_node, persister: persister).characterize(save: false)
      persister.save(resource: saved_node)
    end
  end
end
