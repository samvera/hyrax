module Sufia::Forms
  class CollectionForm < CurationConcerns::Forms::CollectionEditForm
    def rendered_terms
      [:title,
       :creator,
       :contributor,
       :description,
       :tag,
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
