# frozen_string_literal: true

module Hyrax
  # Creates a FileSet and attaches it to a resource
  # and attaches a FileNode to that
  class FileAppender
    attr_reader :storage_adapter, :persister, :files
    def initialize(storage_adapter:, persister:, files:)
      @storage_adapter = storage_adapter
      @persister = persister
      @files = files
    end

    # @param resource [Valkyrie::Resource] the "work" to which FileSets get attached
    # @return the same resource, with member_ids updated. It's up to the caller
    #         persist the changed resource.
    def append_to(resource)
      return resource if files.blank?
      file_sets = build_file_sets(build_file_nodes)
      return resource unless file_sets
      resource.member_ids = resource.member_ids + file_sets.map(&:id)
      resource
    end

    private

      def file_node_builder
        @file_node_builder ||= FileNodeBuilder.new(storage_adapter: storage_adapter,
                                                   persister: persister)
      end

      def build_file_sets(file_nodes)
        return if processing_derivatives?(file_nodes)
        file_nodes.map do |node|
          file_set = create_file_set(node)
          Valkyrie::DerivativeService.for(FileSetChangeSet.new(file_set)).create_derivatives if node.use.include?(Valkyrie::Vocab::PCDMUse.OriginalFile)
          file_set
        end
      end

      def processing_derivatives?(file_nodes)
        !file_nodes.first.use.include?(Valkyrie::Vocab::PCDMUse.OriginalFile)
      end

      def build_file_nodes
        files.map do |file|
          file_node_builder.create(file)
        end
      end

      def create_file_set(file_node)
        persister.save(resource: ::FileSet.new(title: file_node.original_filename, member_ids: file_node.id))
      end
  end
end
