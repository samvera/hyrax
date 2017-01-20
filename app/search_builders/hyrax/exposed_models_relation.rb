module Hyrax
  # A relation that scopes to all user visible models (e.g. works + collections + file sets)
  class ExposedModelsRelation < AbstractTypeRelation
    def allowable_types
      Hyrax.config.curation_concerns + [Collection, ::FileSet]
    end
  end
end
