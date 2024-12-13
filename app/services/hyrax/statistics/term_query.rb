# frozen_string_literal: true
module Hyrax
  module Statistics
    # An abstract class for running a query against the Solr terms component
    # you must implement `index_key` in the concrete class.
    #
    # WARNING: you must use a term that isn't parsed (i.e. use _sim instead of _tesim)
    class TermQuery
      # @api public
      # @param [Integer] limit - Limit the number of responses
      # @return [Array<Hyrax::Statistics::TermQuery::Result>]
      def self.query(limit: 5)
        new(limit).query
      end

      def initialize(limit = 5)
        @limit = limit
      end

      def query
        term = index_key
        # Grab JSON response (looks like {"terms": {"depositor_tesim": {"mjg36": 3}}} for depositor)
        json = Hyrax::SolrService.get(path: 'terms',
                                      'terms.fl': term,
                                      'terms.sort': 'count',
                                      'terms.limit': @limit,
                                      wt: 'json',
                                      'json.nl': 'map',
                                      omitHeader: 'true')
        unless json
          Hyrax.logger.error "Unable to reach TermsComponent via Solr connection. Is it enabled in your solr config?"
          return []
        end

        Result.build(json['terms'][term])
      end

      class Result
        # @param [Array<Array>] rows list of of tuples (label, value)
        def self.build(rows)
          rows.map { |row| Result.new(*row) }
        end

        def initialize(label, value)
          @data = { label: label, data: value }
        end

        def label
          @data[:label]
        end

        def value
          @data[:data]
        end

        # This enables hash equivalence
        def ==(other)
          other == @data
        end

        # Allows us to create a Flot charts pie-graph
        def as_json(opts = nil)
          @data.as_json(opts)
        end
      end
    end
  end
end
