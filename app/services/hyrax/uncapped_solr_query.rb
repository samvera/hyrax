# frozen_string_literal: true

module Hyrax
  # Provides a helper to fetch all Solr results without a hardcoded row cap.
  # Uses a two-pass approach: first queries with rows=0 to get the total count,
  # then fetches all results.
  #
  # The caller provides a block that accepts a row count and returns
  # a Solr response object (one that responds to .response['numFound']
  # and .documents).
  module UncappedSolrQuery
    # @yield [Integer] rows — the number of rows to request
    # @yieldreturn [Blacklight::Solr::Response] Solr response
    # @return [Blacklight::Solr::Response] the full response, or the empty
    #   count response when there are no results
    def self.call
      count_response = yield(0)
      total = count_response.response['numFound']
      return count_response if total.zero?

      yield(total)
    end
  end
end
