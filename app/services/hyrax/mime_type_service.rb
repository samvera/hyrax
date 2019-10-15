module Hyrax
  # Responsible for creating and cleaning up the derivatives of a file_set
  class MimeTypeService
    class << self
      def pdf?(mime_type)
        pdf_mime_types.include? mime_type
      end

      def image?(mime_type)
        image_mime_types.include? mime_type
      end

      def video?(mime_type)
        video_mime_types.include? mime_type
      end

      def audio?(mime_type)
        audio_mime_types.include? mime_type
      end

      def office_document?(mime_type)
        office_document_mime_types.include? mime_type
      end

      def image_mime_types
        ['image/png', 'image/jpeg', 'image/jpg', 'image/jp2', 'image/bmp', 'image/gif', 'image/tiff']
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

      def office_document_mime_types
        ['text/rtf',
         'application/msword',
         'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
         'application/vnd.oasis.opendocument.text',
         'application/vnd.ms-excel',
         'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
         'application/vnd.ms-powerpoint',
         'application/vnd.openxmlformats-officedocument.presentationml.presentation']
      end
    end
  end
end
