module Sufia::Forms
  class CollectionForm < CurationConcerns::Forms::CollectionEditForm
    delegate :id, to: :model

    def primary_terms
      [:title]
    end

    def secondary_terms
      [:creator,
       :contributor,
       :description,
       :keyword,
       :rights,
       :publisher,
       :date_created,
       :subject,
       :language,
       :identifier,
       :based_near,
       :related_url,
       :resource_type]
    end
  end
end
