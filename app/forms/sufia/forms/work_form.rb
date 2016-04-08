module Sufia::Forms
  class WorkForm < CurationConcerns::Forms::WorkForm
    delegate :depositor, :permissions, to: :model
    # Since visibility is not an attribute (it's a method), we need to explicitly delegate to it.
    # TODO: this will be resolved by https://github.com/projecthydra-labs/curation_concerns/pull/708
    delegate :visibility, to: :model

    self.terms += [:collection_ids]

    def [](key)
      return [] if key == :collection_ids
      super
    end

    def primary_terms
      [:title, :creator, :tag, :rights]
    end

    # Fields that are in rendered terms are automatically drawn on the page.
    def secondary_terms
      terms - primary_terms -
        [:files, :visibility_during_embargo, :embargo_release_date,
         :visibility_after_embargo, :visibility_during_lease,
         :lease_expiration_date, :visibility_after_lease, :visibility,
         :thumbnail_id, :representative_id, :ordered_member_ids,
         :collection_ids]
    end

    def self.multiple?(term)
      return true if [:rights, :collection_ids].include? term
      super
    end

    def self.build_permitted_params
      super + [{ collection_ids: [] }]
    end
  end
end
