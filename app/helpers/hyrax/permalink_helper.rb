# frozen_string_literal: true

module Hyrax
  # Helpers for the "Copy permalink" button on work and collection show pages.
  # See documentation/copy_permalink.md.
  module PermalinkHelper
    # The UUID-based URL for the record represented by `presenter`, so
    # it is stable across alias changes and is safe to share or cite.
    def permalink_for(presenter)
      strip_query_string(request.base_url + Hyrax::PermalinkPath.call(presenter))
    end

    def copy_permalink_enabled?
      Flipflop.enabled?(:copy_permalink_button)
    end

    private

    # Removes the `?…` query string from a URL so the permalink is a clean
    # canonical reference. Rails URL helpers append `?locale=...` (and any
    # other registered `default_url_options`) by default; for a stable
    # citable URL we want the bare host + path.
    def strip_query_string(url)
      parsed = URI.parse(url)
      parsed.query = nil
      parsed.fragment = nil
      parsed.to_s
    end
  end
end
