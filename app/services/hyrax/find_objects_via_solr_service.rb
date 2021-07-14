# frozen_string_literal: true
module Hyrax
  # @deprecated This class is being replaced by Hyrax::SolrQueryService #get_objects method.
  #
  # Methods in this class search solr to get the ids and then use the query service to find the objects.
  class FindObjectsViaSolrService
    class_attribute :solr_query_builder, :solr_service, :query_service
    self.solr_query_builder = Hyrax::SolrQueryService
    self.solr_service = Hyrax::SolrService
    self.query_service = Hyrax.query_service

    class << self
      # Find objects matching search criteria.
      # @param model [Class] if not using Valkyrie, this is expected to be an ActiveFedora::Base object that supports #where
      # @param field_pairs [Hash] a list of pairs of property name and values
      # @param join_with [String] the value we're joining the clauses with (default: ' OR ' for backward compatibility with ActiveFedora where)
      # @param type [String] The type of query to run. Either 'raw' or 'field' (default: 'field')
      # @param use_valkyrie [Boolean] if true, return Valkyrie resource(s); otherwise, return ActiveFedora object(s)
      # @return [Array<ActiveFedora::Base|Valkyrie::Resource>] objects matching the query
      def find_for_model_by_field_pairs(model:, field_pairs:, join_with: ' OR ', type: 'field', use_valkyrie: Hyrax.config.use_valkyrie?)
        Deprecation.warn("'##{__method__}' will be removed in Hyrax 4.0.  " \
                         "Instead, use 'Hyrax::SolrQueryService.new.with_model(...).with_field_pairs(...).get_objects'.")

        solr_query_builder.new
                          .with_model(model: model)
                          .with_field_pairs(field_pairs: field_pairs, join_with: join_with, type: type)
                          .get_objects(use_valkyrie: use_valkyrie).to_a
      end
    end
  end
end
