# frozen_string_literal: true
module Hyrax
  module CustomQueries
    ##
    # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
    class FindIdsByModel
      def self.queries
        [:find_ids_by_model]
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
      def find_ids_by_model(model:, ids: :all)
        return query_service.find_all_of_model(model: model).map(&:id) if ids == :all

        query_service.find_many_by_ids(ids: ids).select do |resource|
          resource.is_a?(model)
        end.map(&:id)
      end
    end
  end
end
