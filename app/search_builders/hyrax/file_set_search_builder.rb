# frozen_string_literal: true
module Hyrax
  class FileSetSearchBuilder < ::SearchBuilder
    include SingleResult

    # This overrides the models in FilterByType
    def models
      Hyrax::ModelRegistry.file_set_classes
    end
  end
end
