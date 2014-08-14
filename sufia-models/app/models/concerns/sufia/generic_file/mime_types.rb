module Sufia
  module GenericFile
    module MimeTypes
      extend ActiveSupport::Concern

      def pdf?
        self.class.pdf_mime_types.include? self.mime_type
      end

      def image?
        self.class.image_mime_types.include? self.mime_type
      end

      def video?
        self.class.video_mime_types.include? self.mime_type
      end

      def audio?
        self.class.audio_mime_types.include? self.mime_type
      end

      def office_document?
        self.class.office_document_mime_types.include? self.mime_type
      end

      def collection?
        false
      end

      def file_format
        return nil if self.mime_type.blank? and self.format_label.blank?
        return self.mime_type.split('/')[1]+ " ("+self.format_label.join(", ")+")" unless self.mime_type.blank? or self.format_label.blank?
        return self.mime_type.split('/')[1] unless self.mime_type.blank?
        return self.format_label
      end

      module ClassMethods
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
end
