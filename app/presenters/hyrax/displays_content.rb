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
      streams = stream_urls
      if streams.present?
        streams.collect { |label, _url| video_display_content(label) }
      else
        video_display_content('mp4')
      end
    end

    def video_display_content(label = '')
      IIIFManifest::V3::DisplayContent.new(
        Hyrax::Engine.routes.url_helpers.iiif_av_content_url(id, label: label, host: hostname),
        label: label,
        width: Array(width).first.try(:to_i),
        height: Array(height).first.try(:to_i),
        duration: conformed_duration,
        type: 'Video',
        format: mime_type,
        auth_service: auth_service
      )
    end

    def audio_content
      streams = stream_urls
      if streams.present?
        streams.collect { |label, _url| audio_display_content(label) }
      else
        audio_display_content('mp3')
      end
    end

    def audio_display_content(label = '')
      IIIFManifest::V3::DisplayContent.new(
        Hyrax::Engine.routes.url_helpers.iiif_av_content_url(id, label: label, host: hostname),
        label: label,
        duration: conformed_duration,
        type: 'Sound',
        # I think UV has a bug where if it's 'audio/mpeg' then it would load, so adding this
        # workaround to use 'audio/mp3' (which isn't even an official MIME type).
        format: Hyrax.config.iiif_av_viewer == :universal_viewer ? 'audio/mp3' : mime_type,
        auth_service: auth_service
      )
    end

    def download_path(extension)
      Hyrax::Engine.routes.url_helpers.download_url(object, file: extension, host: hostname)
    end

    def stream_urls
      return {} if object['derivatives_metadata_ssi'].blank?
      files_metadata = JSON.parse(object['derivatives_metadata_ssi'])
      file_locations = files_metadata.select { |f| f['file_location_uri'].present? }
      streams = {}
      if file_locations.present?
        file_locations.each do |f|
          streams[f['label']] = Hyrax.config.iiif_av_url_builder.call(
            f['file_location_uri'],
            hostname
          )
        end
      end
      streams
    end

    # rubocop:disable Metrics/MethodLength
    def auth_service
      return if ability.can?(:read, object)

      {
        "context": "http://iiif.io/api/auth/1/context.json",
        "@id": Rails.application.routes.url_helpers.new_user_session_url(host: hostname, iiif_auth_login: true),
        "@type": "AuthCookieService1",
        "confirmLabel": I18n.t('hyrax.iiif_av.auth.confirmLabel'),
        "description": I18n.t('hyrax.iiif_av.auth.description'),
        "failureDescription": I18n.t('hyrax.iiif_av.auth.failureDescription'),
        "failureHeader": I18n.t('hyrax.iiif_av.auth.failureHeader'),
        "header": I18n.t('hyrax.iiif_av.auth.header'),
        "label": I18n.t('hyrax.iiif_av.auth.label'),
        "profile": "http://iiif.io/api/auth/1/login",
        "service": [
          {
            "@id": Hyrax::Engine.routes.url_helpers.iiif_av_auth_token_url(id: id, host: hostname),
            "@type": "AuthTokenService1",
            "profile": "http://iiif.io/api/auth/1/token"
          },
          {
            "@id": Rails.application.routes.url_helpers.destroy_user_session_url(host: hostname),
            "@type": "AuthLogoutService1",
            "label": I18n.t('hyrax.iiif_av.auth.logoutLabel'),
            "profile": "http://iiif.io/api/auth/1/logout"
          }
        ]
      }
    end
    # rubocop:enable Metrics/MethodLength

    def conformed_duration
      if Array(object.duration)&.first&.count(':') == 3
        # takes care of milliseconds like ["0:0:01:001"]
        Time.zone.parse(Array(object.duration).first.sub(/.*\K:/, '.')).seconds_since_midnight
      elsif Array(object.duration)&.first&.include?(':')
        # if object.duration evaluates to something like ["0:01:00"] which will get converted to seconds
        Time.zone.parse(Array(object.duration).first).seconds_since_midnight
      else
        # handles cases if object.duration evaluates to something like ['25 s']
        Array(object.duration).first.try(:to_f)
      end
    end
  end
  # rubocop:enable Metrics/ModuleLength
end
