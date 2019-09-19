module Hyrax
  module CustomQueries
    class FindManyByAlternateIds
      # Use:
      #   Hyrax.query_service.custom_queries.find_many_by_alternate_ids(alternate_ids: ids)

      def self.queries
        [:find_many_by_alternate_ids]
      end

      attr_reader :query_service

      def initialize(query_service:)
        @query_service = query_service
      end

      # implements a combination of two Valkyrie queries:
      # => find_many_by_ids & find_by_alternate_identifier
      # @param alternate_ids [Enumerator<#to_s>] list of ids
      # @return [Array<Valkyrie::Resource>, Array<ActiveFedora::Base>]
      def find_many_by_alternate_ids(alternate_ids:)
        alternate_ids.uniq.map(&:to_s).each_with_object([]) do |id, resources|
          resources << query_service.find_by_alternate_identifier(alternate_identifier: id)
        end
      end
    end
  end
end
