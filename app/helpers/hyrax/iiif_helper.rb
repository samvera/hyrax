# frozen_string_literal: true
module Hyrax
  module IiifHelper
    def iiif_viewer_display(work_presenter, locals = {})
      render iiif_viewer_display_partial(work_presenter),
             **locals.merge(presenter: work_presenter)
    end

    def iiif_viewer_display_partial(work_presenter)
      'hyrax/base/iiif_viewers/' + work_presenter.iiif_viewer.to_s
    end

    # For backwards compatibility
    def universal_viewer_base_url
      iiif_viewer_base_url(:universal_viewer)
    end

    def iiif_viewer_base_url(viewer)
      case viewer
      when :universal_viewer
        "#{request&.base_url}/uv/uv.html"
      else
        "#{request&.base_url}/#{viewer}/#{viewer}.html"
      end
    end

    def universal_viewer_config_url
      "#{request&.base_url}/uv/uv-config.json"
    end
  end
end
