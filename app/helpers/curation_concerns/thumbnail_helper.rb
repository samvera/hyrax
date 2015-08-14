module CurationConcerns
  module ThumbnailHelper
    def thumbnail_tag(document, _image_options)
      if document.representative.present?
        image_tag main_app.download_path(document.representative, file: 'thumbnail'), alt: 'Thumbnail', class: 'canonical-image'
      else
        content_tag :span, '', class: 'canonical-image'
      end
    end
  end
end
