# frozen_string_literal: true
module Hyrax
  # Methods in this class search solr to get the ids and then use the query service to find the objects.
  class FindObjectsViaSolrService
    class_attribute :solr_query_builder, :solr_service, :query_service
    self.solr_query_builder = Hyrax::SolrQueryBuilderService
    self.solr_service = Hyrax::SolrService
    self.query_service = Hyrax.query_service

    class << self
      # Find objects matching search criteria.
      # @param model [Class]
      # @param field_pairs [Hash] a list of pairs of property name and values
      # @param join_with [String] the value we're joining the clauses with (default: ' OR ' for backward compatibility with ActiveFedora where)
      # @param type [String] The type of query to run. Either 'raw' or 'field' (default: 'field')
      # @param use_valkyrie [Boolean] if true, return Valkyrie resource(s); otherwise, return ActiveFedora object(s)
      # @return [ActiveFedora | Valkyrie::Resource] objects matching the query
      def find_for_model_by_field_pairs(model:, field_pairs:, join_with: ' OR ', type: 'field', use_valkyrie: Hyrax.config.use_valkyrie?)
        query = solr_query_builder.construct_query_for_model(model, field_pairs, join_with, type)
        results = solr_service.query(query)
        ids = results.map(&:id)
        return query_service.find_many_by_ids(ids: ids) if use_valkyrie
        ids.map { |id| query_service.find_by_alternate_identifier(alternate_identifier: id.to_str, use_valkyrie: false) }
      end
    end
  end
end
