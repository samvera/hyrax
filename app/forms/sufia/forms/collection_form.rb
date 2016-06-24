module Sufia::Forms
  class CollectionForm < CurationConcerns::Forms::CollectionEditForm
    delegate :id, to: :model

    # TODO: remove this when https://github.com/projecthydra/hydra-editor/pull/115
    # is merged and hydra-editor 3.0.0 is released
    delegate :model_name, to: :model

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
