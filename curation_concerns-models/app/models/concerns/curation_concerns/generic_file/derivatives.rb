module CurationConcerns
  module GenericFile
    module Derivatives
      extend ActiveSupport::Concern

      included do
        include Hydra::Derivatives
        # This was taken directly from Sufia's GenericFile::Derivative.
        # Using File and ServiceFile so this class will not generate two derivatives 
        # with the same RDF URI. Is there a mime type ontology we should be using instead?
        directly_contains_one :ogg, through: :files, type: ::RDF::URI("http://pcdm.org/use#ServiceFile"), class_name: "Hydra::PCDM::File"
        directly_contains_one :mp3, through: :files, type: ::RDF::URI("http://pcdm.org/use#File"), class_name: "Hydra::PCDM::File"    
        directly_contains_one :mp4, through: :files, type: ::RDF::URI("http://pcdm.org/use#ServiceFile"), class_name: "Hydra::PCDM::File"
        directly_contains_one :webm, through: :files, type: ::RDF::URI("http://pcdm.org/use#File"), class_name: "Hydra::PCDM::File"

        makes_derivatives do |obj|
          case obj.original_file.mime_type
          when *pdf_mime_types
            obj.transform_file :original_file, thumbnail: { format: 'jpg', size: '338x493' }
          when *office_document_mime_types
            obj.transform_file :original_file, { thumbnail: { format: 'jpg', size: '200x150>' } }, processor: :document
           when *audio_mime_types
            obj.transform_file :original_file, { mp3: { format: 'mp3' }, ogg: { format: 'ogg' } }, processor: :audio
          when *video_mime_types
            obj.transform_file :original_file, { webm: { format: 'webm' }, mp4: { format: 'mp4' }, thumbnail: { format: 'jpg' } }, processor: :video
          when *image_mime_types
            obj.transform_file :original_file, thumbnail: { format: 'jpg', size: '200x150>' }
          end
        end
      end
    end
  end
end