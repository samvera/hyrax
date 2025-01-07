# frozen_string_literal: true
module Hyrax
  module CustomQueries
    ##
    # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
    class FindByDateRange
      def self.queries
        [:find_by_date_range]
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
      # @param models [Array]
      # @param start_datetime [DateTime]
      # @param end_datetime [DateTime]
      # @return [Array<Hyrax::Resource>]
      def find_by_date_range(start_datetime:, end_datetime: nil, models: nil)
        end_range = end_datetime.blank? ? '*' : end_datetime.utc.xmlschema
        query = "system_create_dtsi:[#{start_datetime.utc.xmlschema} TO #{end_range}]"
        query += " AND has_model_ssim: (#{models.map { |m| "\"#{m}\"" }.join(' OR ')})" unless models.empty?
        ids = Hyrax::SolrService.query_result(query, fl: 'id')['response']['docs'].map { |doc| doc['id'] }
        Hyrax.query_service.find_many_by_ids(ids: ids)
      end
    end
  end
end
