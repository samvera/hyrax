# frozen_string_literal: true

module Wings
  # Stores a file and an associated FileNode
  class FileNodeBuilder
    attr_reader :storage_adapter, :persister
    def initialize(storage_adapter:, persister:)
      @storage_adapter = storage_adapter
      @persister = persister
    end

    # @param io [JobIOWrapper]
    # @param node [FileNode] the metadata to represent the file
    # @param file_set [FileNode] the associated FileSet
    # @return [FileNode] the persisted metadata node that represents the file
    def create(io:, node:, file_set:)
      file = build_file(io, node.use)
      stored_file = storage_adapter.upload(file: file,
                                           original_filename: io.original_name,
                                           resource: node)
      node.file_identifiers = [stored_file.id]
      attach_file_node(node: node, file_set: file_set)
    end

    def attach_file_node(node:, file_set:)
      existing_node = file_set.original_file || node
      node = existing_node.new(node.to_h.except(:id, :member_ids))
      saved_node = persister.save(resource: node)
      file_set.file_ids = [saved_node.id]
      persister.save(resource: file_set)
      CharacterizeJob.perform_later(saved_node.id.to_s)
      # note the returned saved_node does not yet contain the characterization done in the async job
      saved_node
    end

    private

      # Class for wrapping the file being ingested
      class IoDecorator < SimpleDelegator
        attr_reader :original_filename, :content_type, :use, :tempfile

        # @param [IO] io stream for the file content
        # @param [String] original_filename
        # @param [String] content_type
        # @param [RDF::URI] use the URI for the PCDM predicate indicating the use for this resource
        def initialize(io, original_filename, content_type, use)
          @original_filename = original_filename
          @content_type = content_type
          @use = use
          @tempfile = io
          super(io)
        end
      end

      # Constructs the IoDecorator for ingesting the intermediate file
      # @return [IoDecorator]
      def build_file(io, use)
        # IoDecorator.new(file_stream, original_filename, file_content_type.to_s, use)
        IoDecorator.new(io.file, io.original_name, io.mime_type, use)
      end
  end
end
