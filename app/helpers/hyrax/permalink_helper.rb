# frozen_string_literal: true

module Hyrax
  # Helpers for the "Copy permalink" button on work and collection show pages.
  # See documentation/copy_permalink.md.
  module PermalinkHelper
    # The canonical, UUID-based URL for the record represented by `presenter`.
    # This is the URL the redirect resolver redirects *to*, so it is stable
    # across alias changes and is safe to share or cite. Collections are
    # routed by the Hyrax engine; works are routed by the host app's
    # curation-concern resources.
    def permalink_for(presenter)
      proxy = collection_presenter?(presenter) ? hyrax : main_app
      strip_query_string(polymorphic_url([proxy, presenter]))
    end

    def canonical_url_for(presenter)
      display_path = Hyrax.config.redirects_active? && Hyrax::RedirectsLookup.display_path_for(presenter.id.to_s)
      return permalink_for(presenter) if display_path.blank?
      strip_query_string(request.base_url + display_path)
    end

    def copy_permalink_enabled?
      Flipflop.enabled?(:copy_permalink_button)
    end

    private

    def collection_presenter?(presenter)
      presenter.respond_to?(:collection?) && presenter.collection?
    end

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
