# frozen_string_literal: true
module Hyrax
  module CustomQueries
    ##
    # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
    class FindIdsByModel
      def self.queries
        [:find_ids_by_model]
      end

      def initialize(query_service:, query_rows: 1_000)
        @query_service = query_service
        @query_rows = query_rows
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
      # @param use_solr [Boolean]
      #
      # @return [Enumerable<Valkyrie::ID>]
      def find_ids_by_model(model:, ids: :all, use_solr: true)
        if use_solr
          query_solr(model, ids)
        else
          return query_service.find_all_of_model(model: model).map(&:id) if ids == :all
          query_service.find_many_by_ids(ids: ids).select do |resource|
            resource.is_a?(model)
          end.map(&:id)
        end
      end

      private

      def query_solr(model, ids)
        return enum_for(:query_solr, model, ids) unless block_given?
        model_name = Hyrax::ModelRegistry.rdf_representations_from(Array(model)).first

        solr_query = "_query_:\"{!raw f=has_model_ssim}#{model_name}\""
        solr_response = Hyrax::SolrService.get(solr_query, fl: 'id', rows: @query_rows)['response']

        loop do
          response_docs = solr_response['docs']
          response_docs.select! { |doc| ids.include?(doc['id']) } unless ids == :all

          response_docs.each { |doc| yield doc['id'] }

          break if (solr_response['start'] + solr_response['docs'].count) >= solr_response['numFound']
          solr_response = Hyrax::SolrService.get(solr_query, fl: 'id', rows: @query_rows, start: solr_response['start'] + @query_rows)['response']
        end
      end
    end
  end
end
