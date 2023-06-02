# frozen_string_literal: true
module Hyrax
  module CustomQueries
    ##
    # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
    class FindByReadGroup
      def self.queries
        [:find_by_read_group]
      end

      def initialize(query_service:)
        @query_service = query_service
      end

      attr_reader :query_service
      delegate :resource_factory, to: :query_service

      ##
      # @note this is an unoptimized default implementation of this custom
      #   query. it's Hyrax's policy to provide such implementations of custom
      #   queries in use for cross-compatibility of Valkyrie query services.
      #   it's advisable to provide an optimized query for the specific adapter.
      #
      # @param model [Class]
      # @param ids [Enumerable<#to_s>, Symbol]
      #
      # @return [Enumerable<Valkyrie::ID>]
      def find_by_read_group(models, access_level)
        all_works = models.allowable_types.map { |model| Hyrax.metadata_adapter.query_service.find_all_of_model(model: model).force }
        works_with_access = all_works.flatten.select { |work| work.read_groups.to_a.include?(access_level) }
      end
    end
  end
end
