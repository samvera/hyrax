# frozen_string_literal: true

module Hyrax
  ##
  # Handles presentation for google scholar meta tags.
  #
  # @see https://scholar.google.com/intl/en/scholar/inclusion.html#overview
  class GoogleScholarPresenter < Draper::Decorator
    ##
    # @note Scholar content inclusion docs indicate we should embed metadata
    #   for "scholarly articles - journal papers, conference papers,
    #   technical reports, or their drafts, dissertations, pre-prints,
    #   post-prints, or abstracts." Implementations should try to return
    #   `false` for other content.
    #
    # @return [Boolean] whether this content is "scholarly" for Google Scholar's
    #   purposes. delegates to decorated object if possible.
    #
    # @see https://scholar.google.com/intl/en/scholar/inclusion.html#content
    def scholarly?
      return object.scholarly? if object.respond_to?(:scholarly?)

      true
    end
  end
end
