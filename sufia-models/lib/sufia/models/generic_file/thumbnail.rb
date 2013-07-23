module Sufia
  module GenericFile
    module Thumbnail
      extend ActiveSupport::Concern
      included do
        makes_derivatives_of :content, based_on: :mime_type, when: ['image/png', 'image/jpg'],
             derivatives: { :thumbnail => {size: "200x150>", datastream: 'thumbnail'} }
        makes_derivatives_of :content, based_on: :mime_type, when: ['application/pdf'],
             derivatives: { :thumbnail => {size: "338x493", datastream: 'thumbnail'} }
      end

      # Create thumbnail requires that the characterization has already been run (so mime_type, width and height is available)
      # and that the object is already has a pid set
      def create_thumbnail
        return unless self.content.has_content?

        if video?
          create_video_thumbnail
        else
          create_derivatives
        end
        self.save
      end

      protected
      def create_video_thumbnail
        return unless Sufia.config.enable_ffmpeg
      
        output_file = Dir::Tmpname.create(['sufia', ".png"], Sufia.config.temp_file_base){}
        content.to_tempfile do |f|
          # we could use something like this in order to find a frame in the middle.
          #ffprobe -show_files video.avi 2> /dev/null | grep duration | cut -d= -f2 53.399999  
          command = "#{Sufia.config.ffmpeg_path} -i \"#{f.path}\" -loglevel quiet -vf \"scale=338:-1\"  -r  1  -t  1 #{output_file}"
          system(command)
          raise "Unable to execute command \"#{command}\"" unless $?.success?
        end

        self.thumbnail.content = File.open(output_file, 'rb').read
        self.thumbnail.mimeType = 'image/png'
      end

    end
  end
end
