module Hyrax
  class FileSetSearchBuilder < ::SearchBuilder
    include SingleResult

    # This overrides the models in FilterByType
    def models
      [::FileSet]
    end
  end
end
