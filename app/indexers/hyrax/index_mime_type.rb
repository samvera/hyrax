module Hyrax
  # Copies the mime-type from a FileNode to the FileSet
  class IndexMimeType
    def initialize(resource:)
      @resource = resource
    end

    # Write the mime_type into the solr_document
    # @return [Hash] solr_document the solr document with the mime_type field
    def to_solr
      return {} unless acceptable_type?
      { 'mime_type_ssim' => resource.mime_type }
    end

    private

      attr_reader :resource

      # filter out objects like Works and FileNodes
      def acceptable_type?
        resource.is_a? ::FileSet
      end
  end
end
