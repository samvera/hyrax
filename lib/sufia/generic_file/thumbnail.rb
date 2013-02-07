module Sufia
  module GenericFile
    module Thumbnail
      # Create thumbnail requires that the characterization has already been run (so mime_type, width and height is available)
      # and that the object is already has a pid set
      def create_thumbnail
        return unless self.content.has_content?
        if pdf?
          create_pdf_thumbnail
        elsif image?
          create_image_thumbnail
        # elsif video?
        #   create_video_thumbnail
        end
      end

      protected

      def create_pdf_thumbnail
        retryCnt = 0
        stat = false;
        for retryCnt in 1..3
          begin
            pdf = load_image_transformer
            first = pdf.to_a[0]
            first.format = "PNG"
            thumb = first.scale(338, 493)
            self.thumbnail.content = thumb.to_blob { self.format = "PNG" }
            self.thumbnail.mimeType = 'image/png'
            #logger.debug "Has the content changed before saving? #{self.content.changed?}"
            self.save
            break
          rescue => e
            logger.warn "Rescued an error #{e.inspect} retry count = #{retryCnt}"
            sleep 1
          end
        end
        return stat
      end

      def create_image_thumbnail
        self.thumbnail.content = scale_image.to_blob { self.format = "PNG" }
        self.thumbnail.mimeType = 'image/png'
        #logger.debug "Has the content before saving? #{self.content.changed?}"
        self.save
      end

      def scale_image
        img = load_image_transformer
        height = Float(self.height.first.to_i)
        width = Float(self.width.first.to_i)
        if width > height && width > 150 && height > 105
          # horizontal img
          scale  = 150 / width
          img.scale(150, height * scale)
        elsif height >= width && width > 150 && height > 200
          # vertical or square
          scale  = 200 / height
          img.scale(width*scale, 200)
        else
          # Too small to bother scaling
          img
        end
      end

      # Override this method if you want a different transformer, or need to load the 
      # raw image from a different source (e.g.  external datastream)
      def load_image_transformer
        xformer = Magick::ImageList.new
        xformer.from_blob(content.content)
        xformer
      end

    end
  end
end
