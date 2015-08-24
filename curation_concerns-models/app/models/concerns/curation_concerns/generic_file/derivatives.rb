module CurationConcerns
  module GenericFile
    module Derivatives
      extend ActiveSupport::Concern

      included do
        Hydra::Derivatives.output_file_service = CurationConcerns::PersistDerivatives

        makes_derivatives do |obj|
          case obj.original_file.mime_type
          when *audio_mime_types
            obj.transform_file :original_file, { mp3: { format: 'mp3' }, ogg: { format: 'ogg' } }, processor: :audio
          when *video_mime_types
            obj.transform_file :original_file, { webm: { format: 'webm' }, mp4: { format: 'mp4' } }, processor: :video
          end
        end
      end
    end
  end
end
