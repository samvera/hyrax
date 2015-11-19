module Sufia::Forms
  class CollectionForm < CurationConcerns::Forms::CollectionEditForm
    # Visibility is not settable in Sufia
    self.terms -= [:visibility]
  end
end
