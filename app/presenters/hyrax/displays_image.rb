require 'iiif_manifest'

module Hyrax
  # This gets mixed into FileSetPresenter in order to create
  # a canvas on a IIIF manifest
  module DisplaysImage
    extend ActiveSupport::Concern

    # Creates a display image only where FileSet is an image.
    #
    # @return [IIIFManifest::DisplayImage] the display image required by the manifest builder.
    def display_image
      return nil unless solr_document.image? && current_ability.can?(:read, solr_document)

      latest_file_id = lookup_original_file_id

      return nil unless latest_file_id

      url = Hyrax.config.iiif_image_url_builder.call(
        original_file.id,
        request.base_url,
        Hyrax.config.iiif_image_size_default
      )
      # @see https://github.com/samvera-labs/iiif_manifest
      IIIFManifest::DisplayImage.new(url,
                                     width: solr_document[:width_is],
                                     height: solr_document[:height_is],
                                     iiif_endpoint: iiif_endpoint(original_file.id))
    end

    private

      def iiif_endpoint(file_id)
        return unless Hyrax.config.iiif_image_server?
        IIIFManifest::IIIFEndpoint.new(
          Hyrax.config.iiif_info_url_builder.call(file_id, request.base_url),
          profile: Hyrax.config.iiif_image_compliance_level_uri
        )
      end

      def image_format(channels)
        channels.find { |c| c.include?('rgba') }.nil? ? 'jpg' : 'png'
      end

      def unindexed_current_file_version
        Rails.logger.warn "Indexed current_file_version for #{id} not found, falling back to Fedora."
        ActiveFedora::File.uri_to_id(::FileSet.find(id).current_content_version_uri)
      end

      def lookup_original_file_id
        result = original_file_id
        if result.blank?
          Rails.logger.warn "original_file_id for #{id} not found, falling back to Fedora."
          result = ActiveFedora::File.uri_to_id(::FileSet.find(id).current_content_version_uri)
        end
        result
      end
  end
end
