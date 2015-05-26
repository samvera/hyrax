module CurationConcerns
  module ThumbnailHelper
    def thumbnail_tag(document, image_options)
      if document.representative.present?
        image_tag download_path(document.representative, datastream_id: 'thumbnail'), alt: 'Thumbnail', class: "canonical-image"
      else
        content_tag :span, '', class: 'canonical-image'
      end
    end
  end
end
