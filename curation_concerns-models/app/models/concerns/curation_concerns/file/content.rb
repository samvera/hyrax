module CurationConcerns
  module File
    module Content
      extend ActiveSupport::Concern

      # Basically an alias to Hydra::Works::GenericFile#original_file
      # def content
      #   file_of_type(::RDF::URI("http://pcdm.org/OriginalFile"))
      # end

      included do
        contains "content"
        contains "thumbnail"
      end

      # def thumbnail
      #   file_of_type(::RDF::URI("http://pcdm.org/ThumbnailImage"))
      # end

    end
  end
end
