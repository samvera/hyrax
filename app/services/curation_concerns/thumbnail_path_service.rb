module CurationConcerns
  class ThumbnailPathService
    class << self
      # @param [Work, FileSet] the object to get the thumbnail for
      # @return [String] a path to the thumbnail
      def call(object)
        return default_image unless object.thumbnail_id

        thumb = fetch_thumbnail(object)
        return unless thumb
        if thumb.audio?
          audio_image
        elsif thumbnail?(thumb)
          Rails.application.routes.url_helpers.download_path(object.thumbnail_id, file: 'thumbnail')
        else
          default_image
        end
      end

      def fetch_thumbnail(object)
        return object if object.thumbnail_id == object.id
        ::FileSet.load_instance_from_solr(object.thumbnail_id)
      rescue ActiveFedora::ObjectNotFoundError
        Rails.logger.error("Couldn't find thumbnail #{object.thumbnail_id} for #{object.id}")
        nil
      end

      def default_image
        ActionController::Base.helpers.image_path 'default.png'
      end

      def audio_image
        ActionController::Base.helpers.image_path 'audio.png'
      end

      # @return true if there a file on disk for this object, otherwise false
      def thumbnail?(thumb)
        File.exist?(thumbnail_filepath(thumb))
      end

      def thumbnail_filepath(thumb)
        CurationConcerns::DerivativePath.derivative_path_for_reference(thumb, 'thumbnail')
      end
    end
  end
end
