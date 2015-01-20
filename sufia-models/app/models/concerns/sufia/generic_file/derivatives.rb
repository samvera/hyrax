module Sufia
  module GenericFile
    module Derivatives
      extend ActiveSupport::Concern

      included do
        include Hydra::Derivatives

        makes_derivatives do |obj|
          case obj.mime_type
          when *pdf_mime_types
            obj.transform_file :content, { thumbnail: { format: 'jpg', size: '338x493', datastream: 'thumbnail' } }
          when *office_document_mime_types
            obj.transform_file :content, { thumbnail: { format: 'jpg', size: '200x150>', datastream: 'thumbnail' } }, processor: :document
          when *audio_mime_types
            obj.transform_file :content, { mp3: { format: 'mp3', datastream: 'mp3' }, ogg: { format: 'ogg', datastream: 'ogg' } }, processor: :audio
          when *video_mime_types
            obj.transform_file :content, { webm: { format: 'webm', datastream: 'webm' }, mp4: { format: 'mp4', datastream: 'mp4' }, thumbnail: { format: 'jpg', datastream: 'thumbnail' } }, processor: :video
          when *image_mime_types
            obj.transform_file :content, { thumbnail: { format: 'jpg', size: '200x150>', datastream: 'thumbnail' } }
          end
        end
      end
    end
  end
end
