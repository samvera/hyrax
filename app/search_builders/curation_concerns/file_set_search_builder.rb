module CurationConcerns
  class FileSetSearchBuilder < ::SearchBuilder
    include CurationConcerns::SingleResult

    # This overrides the models in FilterByType
    def models
      [::FileSet.to_class_uri]
    end
  end
end
