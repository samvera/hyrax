# frozen_string_literal: true
module Wings
  module CustomQueries
    ##
    # @see https://github.com/samvera/valkyrie/wiki/Queries#custom-queries
    # @see Hyrax::CustomQueries::FindIdsByModel
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
      # @note uses solr to do the lookup
      #
      # @param model [Class]
      # @param ids [Enumerable<#to_s>, Symbol]
      #
      # @return [Enumerable<Valkyrie::ID>]
      def find_ids_by_model(model:, ids: :all)
        return enum_for(:find_ids_by_model, model: model, ids: ids) unless block_given?
        model_name = ModelRegistry.lookup(model).model_name

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
