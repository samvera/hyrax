# frozen_string_literal: true
module Hyrax
  # A relation that scopes to all user visible models (e.g. works + collections + file sets)
  class ExposedModelsRelation < AbstractTypeRelation
    def allowable_types
      (Hyrax.config.curation_concerns + [Hyrax.config.collection_class, ::Collection, ::FileSet]).uniq
    end
  end
end
