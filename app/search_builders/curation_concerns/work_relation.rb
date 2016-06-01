module CurationConcerns
  class WorkRelation < ActiveFedora::Relation
    def initialize(opts = {})
      super(DummyModel, opts)
    end

    def equivalent_class?(klass)
      CurationConcerns.config.curation_concerns.include?(klass)
    end

    def search_model_clause
      clauses = CurationConcerns.config.curation_concerns.map do |k|
        ActiveFedora::SolrQueryBuilder.construct_query_for_rel(has_model: k.to_s)
      end
      clauses.size == 1 ? clauses.first : "(#{clauses.join(' OR ')})"
    end

    class DummyModel
      def self.primary_concern
        CurationConcerns.config.curation_concerns.first
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
