module CurationConcerns
  class ThumbnailPathService
    class << self
      # @param [Work, FileSet] the object to get the thumbnail for
      # @return [String] a path to the thumbnail
      def call(object)
        return default_image unless object.representative_id

        representative = fetch_representative(object)
        return unless representative
        if representative.audio?
          audio_image
        elsif thumbnail?(representative)
          Rails.application.routes.url_helpers.download_path(object.representative_id, file: 'thumbnail')
        else
          default_image
        end
      end

      def fetch_representative(object)
        return object if object.representative_id == object.id
        ::FileSet.load_instance_from_solr(object.representative_id)
      rescue ActiveFedora::ObjectNotFoundError
        Rails.logger.error("Couldn't find representative #{object.representative_id} for #{object.id}")
        nil
      end

      def default_image
        ActionController::Base.helpers.image_path 'default.png'
      end

      def audio_image
        ActionController::Base.helpers.image_path 'audio.png'
      end

      def thumbnail?(representative)
        File.exist?(thumbnail_filepath(representative))
      end

      def thumbnail_filepath(representative)
        CurationConcerns::DerivativePath.derivative_path_for_reference(representative, 'thumbnail')
      end
    end
  end
end
