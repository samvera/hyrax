# frozen_string_literal: true

module Wings
  # Stores a file and an associated FileNode
  class FileNodeBuilder
    include Hyrax::Noid

    attr_reader :storage_adapter, :persister
    def initialize(storage_adapter:, persister:)
      @storage_adapter = storage_adapter
      @persister = persister
    end

    # @param io_wrapper [JobIOWrapper] with details about the uploaded file
    # @param node [FileNode] the metadata to represent the file
    # @param file_set [FileNode] the associated FileSet
    # @return [FileNode] the persisted metadata node that represents the file
    def create(io_wrapper:, node:, file_set:)
      file = build_file(io_wrapper, node.use)
node.id = ::Valkyrie::ID.new(assign_id)
      stored_file = storage_adapter.upload(file: file,
                                           original_filename: file.original_filename,
                                           # content_type: file.content_type,
                                           resource: node,
                                           id_transformer: Hyrax.config.translate_id_to_uri)
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
        attr_reader :original_filename, :content_type, :content_length, :use, :tempfile

        # @param [IO] io stream for the file content
        # @param [String] original_filename
        # @param [String] content_type
        # @param [RDF::URI] use the URI for the PCDM predicate indicating the use for this resource
        def initialize(io, original_filename, content_type, content_length, use)
          @original_filename = original_filename
          @content_type = content_type
          @content_length = content_length
          @use = use
          @tempfile = io
          super(io)
        end
      end

      # Constructs the IoDecorator for ingesting the intermediate file
      # @param [JobIOWrapper] io wrapper with details about the uploaded file
      # @param [RDF::URI] use the URI for the PCDM predicate indicating the use for this resource
      def build_file(io_wrapper, use)
        IoDecorator.new(io_wrapper.file, io_wrapper.original_name, io_wrapper.mime_type, io_wrapper.size, use)
      end
  end
end
