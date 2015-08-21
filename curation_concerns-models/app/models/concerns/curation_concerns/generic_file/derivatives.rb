module CurationConcerns
  module GenericFile
    module Derivatives
      extend ActiveSupport::Concern

      included do
        # Using File and ServiceFile so that we can have two alternative
        # sound encoding formats and two alternative video formats
        # with unique RDF URIs.
        # TODO: Is there a mime type ontology we should be using instead?
        directly_contains_one :ogg, through: :files, type: ::RDF::URI("http://pcdm.org/use#ServiceFile"), class_name: "Hydra::PCDM::File"
        directly_contains_one :mp3, through: :files, type: ::RDF::URI("http://pcdm.org/use#File"), class_name: "Hydra::PCDM::File"    
        directly_contains_one :mp4, through: :files, type: ::RDF::URI("http://pcdm.org/use#ServiceFile"), class_name: "Hydra::PCDM::File"
        directly_contains_one :webm, through: :files, type: ::RDF::URI("http://pcdm.org/use#File"), class_name: "Hydra::PCDM::File"

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
