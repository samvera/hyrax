# frozen_string_literal: true
module Hyrax
  # A relation that scopes to all user visible models (e.g. works + collections + file sets)
  class ExposedModelsRelation < AbstractTypeRelation
    def allowable_types
      Hyrax::ModelRegistry.work_classes + Hyrax::ModelRegistry.collection_classes + Hyrax::ModelRegistry.file_set_classes
    end
  end
end
