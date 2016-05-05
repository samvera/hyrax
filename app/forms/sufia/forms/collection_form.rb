module Sufia::Forms
  class CollectionForm < CurationConcerns::Forms::CollectionEditForm
    def rendered_terms
      terms - [:visibility]
    end
  end
end
