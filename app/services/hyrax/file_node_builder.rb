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
      stored_file = storage_adapter.upload(file: file,
                                           original_filename: node.original_filename.first,
                                           resource: node)
      node.file_identifiers = [stored_file.id]
      attach_file_node(node: node, file_set: file_set)
    end

    def attach_file_node(node:, file_set:)
      existing_node = file_set.original_file || node
      node = existing_node.new(node.to_h.except(:id, :member_ids))
      saved_node = persister.save(resource: node)
      file_set.member_ids = [saved_node.id]
      persister.save(resource: file_set)
      CharacterizeJob.perform_later(saved_node.id.to_s)
      # note the returned saved_node does not yet contain the characterization done in the async job
      saved_node
    end
  end
end
