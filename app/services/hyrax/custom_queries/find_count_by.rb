# frozen_string_literal: true
module Hyrax
  module CustomQueries
    ##
    # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
    class FindCountBy
      def self.queries
        [:find_count_by]
      end

      def initialize(query_service:)
        @query_service = query_service
      end

      attr_reader :query_service
      delegate :resource_factory, to: :query_service
      delegate :orm_class, to: :resource_factory

      ##
      # @note this is an unoptimized default implementation of this custom
      #   query. it's Hyrax's policy to provide such implementations of custom
      #   queries in use for cross-compatibility of Valkyrie query services.
      #   it's advisable to provide an optimized query for the specific adapter.
      #
      # @param hash [Hash] the hash representation of the query
      def find_count_by(hash = {}, models: nil)
        return nil if models.empty? && hash.blank?
        flat_hash = hash.map { |k, v| "#{k}: \"#{v}\"" }.join(' ')
        flat_hash += " has_model_ssim: (#{models.map { |m| "\"#{m}\"" }.join(' OR ')})" unless models.empty?
        Hyrax::SolrService.count(flat_hash)
      end
    end
  end
end
