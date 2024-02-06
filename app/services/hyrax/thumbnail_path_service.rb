# frozen_string_literal: true
module Hyrax
  class ThumbnailPathService
    class << self
      # @param [#id] object - to get the thumbnail for
      # @return [String] a path to the thumbnail
      def call(object)
        return default_image if object.try(:thumbnail_id).blank?

        thumb = fetch_thumbnail(object)

        return default_image unless thumb
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
        return object if object.thumbnail_id == object.id ||
                         object.try(:file_ids)&.detect { |fid| fid == object.thumbnail_id }
        begin
          # In some implmentations (e.g. Wings), `find_by(id:)` aliases
          # `find_by_alternate_identifier`  but that is not guaranteed.
          return Hyrax.query_service.find_by(id: object.thumbnail_id)
        rescue
          nil
        end
        Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: object.thumbnail_id)
      rescue Valkyrie::Persistence::ObjectNotFoundError, Hyrax::ObjectNotFoundError
        Hyrax.logger.error("Couldn't find thumbnail #{object.thumbnail_id} for #{object.id}")
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
        File.exist?(thumbnail_filepath(thumb)) ||
          (thumb.is_a?(Hyrax::Resource) && file_in_storage?(thumb))
      end

      # @param [FileSet] thumb - the object that is the thumbnail
      def thumbnail_filepath(thumb)
        Hyrax::DerivativePath.derivative_path_for_reference(thumb, 'thumbnail')
      end

      def file_in_storage?(thumb)
        Hyrax.custom_queries.find_thumbnail(file_set: thumb)
      rescue Valkyrie::StorageAdapter::FileNotFound, Valkyrie::Persistence::ObjectNotFoundError
        false
      end
    end
  end
end
