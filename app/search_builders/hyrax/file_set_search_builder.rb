# frozen_string_literal: true
module Hyrax
  class FileSetSearchBuilder < ::SearchBuilder
    include SingleResult

    # This overrides the models in FilterByType
    def models
      [::FileSet, ::Hyrax::FileSet]
    end
  end
end
