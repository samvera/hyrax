# frozen_string_literal: true

module Hyrax
  # rubocop:disable Metrics/ModuleLength
  module DisplaysContent
    extend ActiveSupport::Concern
    # Creates a display content only where FileSet is an image, audio, or video.
    #
    # @return [IIIFManifest::V3::DisplayContent] the display content required by the manifest builder.
    def display_content
      return nil unless display_content?

      return image_content if image?
      return video_content if video?
      return audio_content if audio?
    end

    private

    def display_content?
      return false unless Flipflop.iiif_av?

      content_supported? && ability.can?(:read, object)
    end

    def content_supported?
      video? || audio? || image?
    end

    def image_content
      return nil unless latest_file_id
      # Only provide v3 content when using v3 factory
      # Otherwise let display_image handle v2
      return nil unless Hyrax.config.iiif_manifest_factory == ::IIIFManifest::V3::ManifestFactory

      url = Hyrax.config.iiif_image_url_builder.call(
        latest_file_id,
        hostname,
        Hyrax.config.iiif_image_size_default,
        image_format(alpha_channels)
      )

      image_content_v3(url)
    end

    def image_content_v3(url)
      # @see https://github.com/samvera-labs/iiif_manifest
      IIIFManifest::V3::DisplayContent.new(
        url,
        format: image_format(alpha_channels),
        width: width,
        height: height,
        type: 'Image',
        iiif_endpoint: iiif_endpoint(latest_file_id)
      )
    end

    def video_content
      # @see https://github.com/samvera-labs/iiif_manifest
      IIIFManifest::V3::DisplayContent.new(
        download_path('mp4'),
        label: 'mp4',
        width: Array(width).first.try(:to_i),
        height: Array(height).first.try(:to_i),
        duration: conformed_duration,
        type: 'Video',
        format: mime_type
      )
    end

    def audio_content
      IIIFManifest::V3::DisplayContent.new(
        download_path('mp3'),
        label: 'mp3',
        duration: conformed_duration,
        type: 'Sound',
        # I think UV has a bug where if it's 'audio/mpeg' then it would load, so adding this
        # workaround to use 'audio/mp3' (which isn't even an official MIME type).
        format: Hyrax.config.iiif_av_viewer == :universal_viewer ? 'audio/mp3' : mime_type
      )
    end

    def download_path(extension)
      Hyrax::Engine.routes.url_helpers.download_url(object, file: extension, host: hostname)
    end

    # rubocop:disable Metrics/AbcSize
    def conformed_duration
      duration_string = Array(object.duration).first
      return nil if duration_string.blank?

      # Handle plain numeric values (e.g., "25 s", "120")
      return duration_string.to_f unless duration_string.include?(':')

      # Parse time-formatted strings
      parts = duration_string.split(':').map(&:to_i)

      case parts.length
      when 2 # MM:SS
        parts[0] * 60.0 + parts[1]
      when 3 # H:MM:SS
        parts[0] * 3600.0 + parts[1] * 60.0 + parts[2]
      when 4 # H:MM:SS:mmm (milliseconds)
        parts[0] * 3600.0 + parts[1] * 60.0 + parts[2] + (parts[3] / 1000.0)
      else
        duration_string.to_f # fallback
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
  # rubocop:enable Metrics/ModuleLength
end
