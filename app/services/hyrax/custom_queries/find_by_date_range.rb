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
      def find_by_date_range(start_datetime:, end_datetime: nil, models: nil)
        end_datetime = 1.second.since(Time.zone.now) if end_datetime.blank?
        if models.present?
          query_service.run_query(find_models_by_date_range_query, start_datetime.to_s, end_datetime.to_s, models)
        else
          query_service.run_query(find_by_date_range_query, start_datetime.to_s, end_datetime.to_s)
        end
      end

      def find_models_by_date_range_query
        <<-SQL
          SELECT * FROM orm_resources
          WHERE created_at >= ?
          AND created_at <= ?
          AND internal_resource IN (?);
        SQL
      end

      def find_by_date_range_query
        <<-SQL
          SELECT * FROM orm_resources
          WHERE created_at >= ?
          AND created_at <= ?;
        SQL
      end
    end
  end
end
