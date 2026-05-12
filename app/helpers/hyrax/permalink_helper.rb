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
      polymorphic_url([proxy, presenter])
    end

    def copy_permalink_enabled?
      Flipflop.enabled?(:copy_permalink_button)
    end

    private

    def collection_presenter?(presenter)
      presenter.respond_to?(:collection?) && presenter.collection?
    end
  end
end
