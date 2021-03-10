# frozen_string_literal: true

module Hyrax
  ##
  # Handles presentation for google scholar meta tags.
  #
  # @example
  #   my_book = Monograph.new(title: ['On Moomins'], creator: ['Tove', 'Lars'])
  #   scholar = GoogleScholarPresenter.new(my_book)
  #
  #   scholar.title => 'On Moomins'
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

    ##
    # @note Google Scholar cares about author order. when possible, this should
    #   return the othors in order. delegates to `#ordered_authors` when
    #   available.
    #
    # @return [Array<String>] an ordered array of author names
    def authors
      return object.ordered_authors if object.respond_to?(:ordered_authors)

      Array(object.creator)
    end

    ##
    # @note falls back on {#title} if no description can be found. this
    #   probably isn't great.
    #
    # @return [String] a description
    def description
      (Array(object.try(:description)).first || title).truncate(200)
    end

    ##
    # @return [String] the keywords
    def keywords
      Array(object.try(:keyword)).join('; ')
    end

    ##
    # @todo this should probably only return a present value if a PDF is
    #   available!
    #
    # @return [#to_s]
    def pdf_url
      object.try(:download_url)
    end

    ##
    # @return [String] the publication date
    def publication_date
      Array(object.try(:date_created)).first || ''
    end

    ##
    # @return [String] a string representing the publisher
    def publisher
      Array(object.try(:publisher)).join('; ')
    end

    ##
    # @return [String] exactly one title; the same one every time
    def title
      Array(object.try(:title)).sort.first || ""
    end
  end
end
