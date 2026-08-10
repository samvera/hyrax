# frozen_string_literal: true
module Hyrax
  ##
  # Renders thumbnails with `loading="lazy"` by default.
  #
  # @see Blacklight::ThumbnailPresenter
  class ThumbnailPresenter < Blacklight::ThumbnailPresenter
    # Used by the slideshow view, via `Blacklight::Gallery::SlideshowPreviewComponent`.
    def render(image_options = {})
      super(lazy(image_options))
    end

    def thumbnail_tag(image_options = {}, url_options = {})
      super(lazy(image_options), url_options)
    end

    private

    def lazy(image_options)
      { loading: 'lazy' }.merge(image_options)
    end
  end
end

