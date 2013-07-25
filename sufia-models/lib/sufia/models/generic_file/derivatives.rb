module Sufia
  module GenericFile
    module Derivatives
      extend ActiveSupport::Concern

      included do
        include Hydra::Derivatives

        makes_derivatives do |obj| 
          case obj.mime_type
          when *pdf_mime_types
            obj.transform_datastream :content, 
              { :thumbnail => {size: "338x493", datastream: 'thumbnail'} }
          when *audio_mime_types
            obj.transform_datastream :content,
              { :mp3 => {format: 'mp3', datastream: 'mp3'},
                :ogg => {format: 'ogg', datastream: 'ogg'} }, processor: :audio
          when *video_mime_types
            obj.transform_datastream :content,
              { :webm => {format: "webm", datastream: 'webm'}, 
                :mp4 => {format: "mp4", datastream: 'mp4'} }, processor: :video
          when *image_mime_types
            obj.transform_datastream :content, { :thumbnail => {size: "200x150>", datastream: 'thumbnail'} }
          end
        end
      end

    end
  end
end

