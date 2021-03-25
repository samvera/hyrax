# frozen_string_literal: true
module Hyrax
  class ThumbnailPathService
    class << self
      # @param [#id] object - to get the thumbnail for
      # @return [String] a path to the thumbnail
      def call(object)
        return default_image if object.try(:thumbnail_id).blank?

        thumb = fetch_thumbnail(object)

        return unless thumb
        return call(thumb) unless thumb.file_set?
        if audio?(thumb)
          audio_image
        elsif thumbnail?(thumb)
          thumbnail_path(thumb)
        else
          default_image
        end
      end

      private

      def audio?(thumb)
        service = thumb.respond_to?(:audio?) ? thumb : Hyrax::FileSetTypeService.new(file_set: thumb)
        service.audio?
      end

      def fetch_thumbnail(object)
        return object if object.thumbnail_id == object.id
        Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: object.thumbnail_id)
      rescue Valkyrie::Persistence::ObjectNotFoundError, Hyrax::ObjectNotFoundError
        Rails.logger.error("Couldn't find thumbnail #{object.thumbnail_id} for #{object.id}")
        nil
      end

      # @return the network path to the thumbnail
      # @param [FileSet] thumbnail the object that is the thumbnail
      def thumbnail_path(thumbnail)
        Hyrax::Engine.routes.url_helpers.download_path(thumbnail.id,
                                                       file: 'thumbnail')
      end

      def default_image
        ActionController::Base.helpers.image_path 'default.png'
      end

      def audio_image
        ActionController::Base.helpers.image_path 'audio.png'
      end

      # @return true if there a file on disk for this object, otherwise false
      # @param [FileSet] thumb - the object that is the thumbnail
      def thumbnail?(thumb)
        File.exist?(thumbnail_filepath(thumb))
      end

      # @param [FileSet] thumb - the object that is the thumbnail
      def thumbnail_filepath(thumb)
        Hyrax::DerivativePath.derivative_path_for_reference(thumb, 'thumbnail')
      end
    end
  end
end
