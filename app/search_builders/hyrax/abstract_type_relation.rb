# frozen_string_literal: true
module Hyrax
  class AbstractTypeRelation < ActiveFedora::Relation
    def initialize(opts = {})
      super(DummyModel, opts)
    end

    def allowable_types
      raise NotImplementedException, "Implement allowable_types in a subclass"
    end

    def equivalent_class?(klass)
      allowable_types.include?(klass)
    end

    def search_model_clause
      clauses = allowable_types.map do |k|
        ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: k.to_s)
      end
      # empty array returns nil, AF finder method handles it properly, see hyrax issue #2844
      clauses.size <= 1 ? clauses.first : "(#{clauses.join(' OR ')})"
    end

    class DummyModel
      def self.primary_concern
        Hyrax.config.curation_concerns.first
      end

      def self.delegated_attributes
        primary_concern.delegated_attributes
      end

      def self.solr_query_handler
        primary_concern.solr_query_handler
      end

      def self.default_sort_params
        primary_concern.default_sort_params
      end

      def self.id_to_uri(*args)
        primary_concern.id_to_uri(*args)
      end
    end
  end
end
