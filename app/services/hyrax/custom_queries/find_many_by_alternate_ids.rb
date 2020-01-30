module Hyrax
  module CustomQueries
    class FindManyByAlternateIds
      # Use:
      #   Hyrax.custom_queries.find_many_by_alternate_ids(alternate_ids: ids)

      def self.queries
        [:find_many_by_alternate_ids]
      end

      attr_reader :query_service

      def initialize(query_service:)
        @query_service = query_service
      end

      # implements a combination of two Valkyrie queries:
      # => find_many_by_ids & find_by_alternate_identifier
      #
      # @param alternate_ids [Enumerator<#to_s>] list of ids
      # @return [Enumerable<Valkyrie::Resource>, Enumerable<ActiveFedora::Base>]
      def find_many_by_alternate_ids(alternate_ids:)
        return enum_for(:find_many_by_alternate_ids, alternate_ids: alternate_ids) unless
          block_given?

        alternate_ids.uniq do |id|
          yield query_service.find_by_alternate_identifier(alternate_identifier: id.to_s)
        end
      end
    end
  end
end
