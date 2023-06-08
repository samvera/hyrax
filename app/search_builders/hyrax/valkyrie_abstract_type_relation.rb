# frozen_string_literal: true

module Hyrax
  class ValkyrieAbstractTypeRelation
    def initialize(allowable_types: nil, **opts)
      @allowable_types = allowable_types
      # super(DummyModel, opts)
    end

    def allowable_types
      @allowable_types.present? ||
        raise(NotImplementedException, "Implement allowable_types in a subclass")
    end

    def equivalent_class?(klass)
      allowable_types.include?(klass)
    end

    def count
      Hyrax.query_service.custom_queries.find_count_by(models: allowable_types)
    end

    def where(hash)
      Hyrax.query_service.find_references_by(resource: hash.values.first, property: hash.keys.first)
    end

    # class DummyModel

    #   # def self.delegated_attributes
    #   # end
    # end

  end
end
