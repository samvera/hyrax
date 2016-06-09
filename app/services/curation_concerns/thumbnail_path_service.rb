module CurationConcerns
  class ThumbnailPathService
    class << self
      # @param [Work, FileSet] the object to get the thumbnail for
      # @return [String] a path to the thumbnail
      def call(object)
        return default_image unless object.thumbnail_id

        thumb = fetch_thumbnail(object)
        return unless thumb
        return call(thumb) unless thumb.is_a?(::FileSet)
        if thumb.audio?
          audio_image
        elsif thumbnail?(thumb)
          thumbnail_path(thumb)
        else
          default_image
        end
      end

      protected

        def fetch_thumbnail(object)
          return object if object.thumbnail_id == object.id
          ::ActiveFedora::Base.find(object.thumbnail_id)
        rescue ActiveFedora::ObjectNotFoundError
          Rails.logger.error("Couldn't find thumbnail #{object.thumbnail_id} for #{object.id}")
          nil
        end

        # @return the network path to the thumbnail
        # @param [FileSet] thumbnail the object that is the thumbnail
        def thumbnail_path(thumbnail)
          Rails.application.routes.url_helpers.download_path(thumbnail.id,
                                                             file: 'thumbnail')
        end

        def default_image
          ActionController::Base.helpers.image_path 'default.png'
        end

        def audio_image
          ActionController::Base.helpers.image_path 'audio.png'
        end

        # @return true if there a file on disk for this object, otherwise false
        # @param [FileSet] thumbnail the object that is the thumbnail
        def thumbnail?(thumb)
          File.exist?(thumbnail_filepath(thumb))
        end

        # @param [FileSet] thumbnail the object that is the thumbnail
        def thumbnail_filepath(thumb)
          CurationConcerns::DerivativePath.derivative_path_for_reference(thumb, 'thumbnail')
        end
    end
  end
end
