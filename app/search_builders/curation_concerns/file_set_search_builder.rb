module CurationConcerns
  class FileSetSearchBuilder < ::SearchBuilder
    include CurationConcerns::SingleResult

    # This overrides the models in FilterByType
    def models
      [::FileSet]
    end
  end
end
