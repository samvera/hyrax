module Hyrax
  module Riiif
    # Maps between a FileNode identifier and a Riiif::File
    class ValkyrieFileResolver
      # @param id [String] the identifier of a Hyrax::FileNode
      # @return [Riiif::File] the file to display
      def find(id)
        file_node = Hyrax::Queries.find_by(id: Valkyrie::ID.new(id))
        ::Riiif::File.new(file_node.file.disk_path)
      end
    end
  end
end
