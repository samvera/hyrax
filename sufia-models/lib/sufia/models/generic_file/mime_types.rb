module Sufia
  module GenericFile
    module MimeTypes
      extend ActiveSupport::Concern

      module ClassMethods
        def image_mime_types
          ['image/png','image/jpeg', 'image/jpg', 'image/jp2', 'image/bmp', 'image/gif']
        end

        def pdf_mime_types
          ['application/pdf']
        end

        def video_mime_types
          ['video/mpeg', 'video/mp4', 'video/webm', 'video/x-msvideo', 'video/avi', 'video/quicktime', 'application/mxf']
        end

        def audio_mime_types
          # audio/x-wave is the mime type that fits 0.6.0 returns for a wav file.
          # audio/mpeg is the mime type that fits 0.6.0 returns for an mp3 file.
          ['audio/mp3', 'audio/mpeg', 'audio/wav', 'audio/x-wave', 'audio/x-wav', 'audio/ogg']
        end
      end
    end
  end
end
