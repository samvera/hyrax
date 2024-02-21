# frozen_string_literal: true
module Hyrax
  module CustomQueries
    ##
    # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
    class FindModelsByAccess
      def self.queries
        [:find_models_by_access]
      end

      def initialize(*)
        @query_service = Hyrax.query_service
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
      # @param model [Class]
      # @param ids [Enumerable<#to_s>, Symbol]
      #
      def find_models_by_access(mode:, models: nil, agent:, group: nil)
        agent = "group/#{agent}" if group.present?
        internal_array = "{\"permissions\": [{\"mode\": \"#{mode}\", \"agent\": \"#{agent}\"}]}"
        if models.present?
          query_service.run_query(find_models_by_access_query, internal_array, models)
        else
          query_service.run_query(find_by_access_query, internal_array)
        end
      end

      def find_models_by_access_query
        <<-SQL
          SELECT * FROM orm_resources
          WHERE id IN (
            SELECT uuid(metadata::json#>'{access_to,0}'->>'id') FROM orm_resources
            WHERE metadata @> ?
          ) AND internal_resource IN (?);
        SQL
      end

      def find_by_access_query
        <<-SQL
          SELECT * FROM orm_resources
          WHERE id IN (
            SELECT uuid(metadata::json#>'{access_to,0}'->>'id') FROM orm_resources
            WHERE metadata @> ?
          );
        SQL
      end
    end
  end
end
