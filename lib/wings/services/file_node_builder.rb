# frozen_string_literal: true
require 'wings/hydra/works/services/add_file_node_to_file_set'

# TODO: The file_node resource and the file_node_builder should be in Hyrax as they will be needed for non-wings valkyrie implementations too.

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
    # @param file_set [Valkyrie::Resouce, Hydra::Works::FileSet] the associated FileSet # TODO: Remove Hydra::Works::FileSet as a potential type when valkyrization is complete.
    # @return [FileNode] the persisted metadata node that represents the file
    def create(io_wrapper:, node:, file_set:)
      io_wrapper = build_file(io_wrapper, node.use)
      file_set.save unless file_set.persisted?
      node.id = ::Valkyrie::ID.new(assign_id)
      node.file_set_id = file_set.id
      stored_file = storage_adapter.upload(file: io_wrapper,
                                           original_filename: io_wrapper.original_filename,
                                           content_type: io_wrapper.content_type,
                                           resource: node,
                                           resource_uri_transformer: Hyrax.config.resource_id_to_uri_transformer)
      node.file_identifiers = [stored_file.id]
      attach_file_node(node: node, file_set: file_set)
    end

    def attach_file_node(node:, file_set:)
      saved_node = file_set.is_a?(::Valkyrie::Resource) ? attach_file_node_to_valkyrie_file_set(node, file_set) : node

      # note the returned saved_node does not yet contain the characterization done in the async job
      CharacterizeJob.perform_later(saved_node.file_identifiers.first.to_s) # TODO: What id is the correct one for the file? Check where this is called outside of wings.
      saved_node
    end

    def attach_file_node_to_valkyrie_file_set(node, file_set)
      # This is for storage adapters other than wings.  The wings storage adapter already attached the file to the file_set.
      # This process is a no-op for wings.  TODO: May need to verify this is a no-op once file_set is passed in as a resource.
      existing_node = file_set.original_file || node
      node = existing_node.new(node.to_h.except(:id, :member_ids))
      saved_node = persister.save(resource: node)
      file_set.file_ids = [saved_node.id]
      persister.save(resource: file_set)
      saved_node
    end

    private

      # Class for wrapping the file being ingested
      class IoDecorator < SimpleDelegator
        attr_reader :original_filename, :content_type, :length, :use, :tempfile

        # @param [IO] io stream for the file content
        # @param [String] original_filename
        # @param [String] content_type
        # @param [RDF::URI] use the URI for the PCDM predicate indicating the use for this resource
        def initialize(io, original_filename, content_type, content_length, use)
          @original_filename = original_filename
          @content_type = content_type
          @length = content_length
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
