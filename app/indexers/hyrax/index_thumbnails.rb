module Hyrax
  class IndexThumbnails
    class_attribute :thumbnail_path_service
    self.thumbnail_path_service = ThumbnailPathService
    class_attribute :thumbnail_field
    self.thumbnail_field = 'thumbnail_path_ss'.freeze

    def initialize(resource:)
      @resource = resource
    end

    # Write the thumbnail paths into the solr_document
    # @return [Hash] solr_document the solr document with the thumbnail field
    def to_solr
      return {} unless acceptable_type?
      { thumbnail_field => thumbnail_path }
    end

    private

      attr_reader :resource

      # filter out objects like Embargos and FileNodes
      def acceptable_type?
        @resource.respond_to?(:thumbnail_id) && @resource.thumbnail_id
      end

      # Returns the value for the thumbnail path to put into the solr document
      def thumbnail_path
        self.class.thumbnail_path_service.call(resource)
      end
  end
end
