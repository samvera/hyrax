# frozen_string_literal: true
module Hyrax
  module CustomQueries
    ##
    # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
    class FindModelsByAccess
      def self.queries
        [:find_models_by_access]
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
      # @param model [Class]
      # @param ids [Enumerable<#to_s>, Symbol]
      # @return [Array<Hyrax::Resource>]
      #
      def find_models_by_access(mode:, models: nil, agent:, group: nil)
        query = "#{Hydra.config.permissions[mode.to_sym][(group ? 'group' : 'individual').to_sym]}:#{agent}"
        query += " AND has_model_ssim: (#{models.map { |m| "\"#{m}\"" }.join(' OR ')})" unless models.empty?
        ids = Hyrax::SolrService.query_result(query, fl: 'id')['response']['docs'].map { |doc| doc['id'] }
        Hyrax.query_service.find_many_by_ids(ids: ids)
      end
    end
  end
end
