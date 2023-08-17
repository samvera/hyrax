# frozen_string_literal: true
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
      return nil unless latest_file_id

      # @see https://github.com/samvera-labs/iiif_manifest
      IIIFManifest::DisplayImage.new(display_image_url(request.base_url),
                                     format: image_format(alpha_channels),
                                     width: width,
                                     height: height,
                                     iiif_endpoint: iiif_endpoint(latest_file_id))
    end

    private

    def display_image_url(base_url)
      Hyrax.config.iiif_image_url_builder.call(
        latest_file_id,
        base_url,
        Hyrax.config.iiif_image_size_default,
        format: image_format(alpha_channels)
      )
    end

    def iiif_endpoint(file_id, base_url: request.base_url)
      return unless Hyrax.config.iiif_image_server?
      IIIFManifest::IIIFEndpoint.new(
        Hyrax.config.iiif_info_url_builder.call(file_id, base_url),
        profile: Hyrax.config.iiif_image_compliance_level_uri
      )
    end

    def image_format(channels)
      channels&.include?('rgba') ? 'png' : 'jpg'
    end

    ##
    # @api private
    #
    # Get the id for the latest version of original file. If
    # `#originial_file_id` is available on the object, simply use that value.
    # Otherwise, retrieve the original file directly from the datastore and
    # resolve the current version using `VersioningService`.
    #
    # The fallback lookup normally happens when a File Set was indexed prior
    # to the introduction of `#original_file_id` to the index document,
    # but is useful as a generalized failsafe to ensure we have done our best
    # to resolve the content.
    #
    # @note this method caches agressively. it's here to support IIIF
    #   manifest generation and we expect this object to exist only for
    #   the generation of a single manifest document. this insulates callers
    #   from the complex lookup behavior and protects against expensive and
    #   unnecessary database lookups.
    def latest_file_id
      @latest_file_id ||=
        begin
          result = original_file_id

          if result.blank?
            Hyrax.logger.warn "original_file_id for #{id} not found, falling back to Fedora."
            result = Hyrax::VersioningService.versioned_file_id ::FileSet.find(id).original_file
          end

          result
        end
    end
  end
end
