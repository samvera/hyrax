module Hyrax
  # A search builder that scopes to all user visible models (e.g. works + collections + file sets)
  class ExposedModelsSearchBuilder < ::SearchBuilder
    self.default_processor_chain = [:filter_models]

    private

      # This overrides the models in FilterByType
      def models
        Hyrax.config.curation_concerns + [Collection, ::FileSet]
      end
  end
end
