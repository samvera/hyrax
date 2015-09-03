module CurationConcerns
  class ThumbnailPathService
    class << self
      # @param [GenericWork, GenericFile] the object to get the thumbnail for
      # @return [String] a path to the thumbnail
      def call(object)
        return default_image unless object.representative

        representative = fetch_representative(object)
        return unless representative
        if representative.audio?
          audio_image
        elsif representative.thumbnail
          Rails.application.routes.url_helpers.download_path(object.representative, file: 'thumbnail')
        else
          default_image
        end
      end

      def fetch_representative(object)
        return object if object.representative == object.id
        ::GenericFile.load_instance_from_solr(object.representative)
      rescue ActiveFedora::ObjectNotFoundError
        Rails.logger.error("Couldn't find representative #{object.representative} for #{object.id}")
        nil
      end

      def default_image
        ActionController::Base.helpers.image_path 'default.png'
      end

      def audio_image
        ActionController::Base.helpers.image_path 'audio.png'
      end
    end
  end
end
