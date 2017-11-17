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
      stored_file = storage_adapter.upload(file: file,
                                           original_filename: node.original_filename.first,
                                           resource: node)
      node.file_identifiers = node.file_identifiers + [stored_file.id]
      node = Valkyrie::FileCharacterizationService.for(file_node: node, persister: persister).characterize(save: false)
      persister.save(resource: node)
    end
  end
end
