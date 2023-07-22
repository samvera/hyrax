# frozen_string_literal: true

module Hyrax
  class ValkyrieAbstractTypeRelation
    def initialize(allowable_types: nil, _opts: {})
      @allowable_types = allowable_types
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

    def ==(other)
      case other
      when Relation
        other.where_values == where_values
      when Array
        to_a == other
      end
    end

    delegate :inspect, to: :to_a
  end
end
