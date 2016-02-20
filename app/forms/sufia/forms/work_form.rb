module Sufia::Forms
  class WorkForm < CurationConcerns::Forms::WorkForm
    delegate :depositor, :permissions, to: :model

    def rendered_terms
      terms - [:files, :visibility_during_embargo, :embargo_release_date,
               :visibility_after_embargo, :visibility_during_lease,
               :lease_expiration_date, :visibility_after_lease, :visibility, :thumbnail_id, :representative_id, :ordered_member_ids]
    end
  end
end
