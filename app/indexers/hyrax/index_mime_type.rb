# frozen_string_literal: true

module Hyrax
  # Copies the mime-type from a FileNode to the FileSet
  class IndexMimeType
    class_attribute :file_format_field, :mime_type_field
    self.file_format_field = 'file_format_ssim'
    self.mime_type_field = 'mime_type_ssim'

    def initialize(resource:)
      @resource = resource
    end

    # Write the mime_type into the solr_document
    # @return [Hash] solr_document the solr document with the mime_type field
    def to_solr
      return {} unless acceptable_type?
      { mime_type_field => resource.mime_type,
        file_format_field => file_format }
    end

    private

      attr_reader :resource

      # filter out objects like Works and FileNodes
      def acceptable_type?
        resource.is_a? ::FileSet
      end

      def file_format
        if resource.mime_type.present? && resource.format_label.present?
          "#{resource.mime_type.split('/').last} (#{resource.format_label.join(', ')})"
        elsif resource.mime_type.present?
          resource.mime_type.split('/').last
        elsif resource.format_label.present?
          resource.format_label
        end
      end
  end
end
