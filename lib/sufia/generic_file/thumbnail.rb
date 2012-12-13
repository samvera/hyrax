module Sufia
  module GenericFile
    module Thumbnail
      # Create thumbnail requires that the characterization has already been run (so mime_type, width and height is available)
      # and that the object is already has a pid set
      def create_thumbnail
        return if self.content.content.nil?
        if ["application/pdf"].include? self.mime_type
          create_pdf_thumbnail
        elsif ["image/png","image/jpeg", "image/gif"].include? self.mime_type
          create_image_thumbnail
        # TODO: if we can figure out how to do video (ffmpeg?)
        #elsif ["video/mpeg", "video/mp4"].include? self.mime_type
        end
      end

      def create_pdf_thumbnail
        retryCnt = 0
        stat = false;
        for retryCnt in 1..3
          begin
            pdf = Magick::ImageList.new
            pdf.from_blob(content.content)
            first = pdf.to_a[0]
            first.format = "PNG"
            thumb = first.scale(338, 493)
            self.thumbnail.content = thumb.to_blob { self.format = "PNG" }
            #logger.debug "Has the content changed before saving? #{self.content.changed?}"
            self.terms_of_service = '1'
            stat = self.save
            break
          rescue => e
            logger.warn "Rescued an error #{e.inspect} retry count = #{retryCnt}"
            sleep 1
          end
        end
        return stat
      end

      def create_image_thumbnail
        img = Magick::ImageList.new
        img.from_blob(content.content)
        # horizontal img
        height = self.height.first.to_i
        width = self.width.first.to_i
        scale = height / width
        if width > height
          if width > 150 and height > 105
            thumb = img.scale(150, height/scale)
          else
            thumb = img.scale(width, height)
          end
        # vertical img
        else
          if width > 150 and height > 200
            thumb = img.scale(150*scale, 200)
          else
            thumb = img.scale(width, height)
          end
        end
        self.thumbnail.content = thumb.to_blob
        self.terms_of_service = '1'
        #logger.debug "Has the content before saving? #{self.content.changed?}"
        self.save
      end
    end
  end
end
