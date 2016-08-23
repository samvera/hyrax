module Sufia::Forms
  class WorkForm < CurationConcerns::Forms::WorkForm
    delegate :depositor, :on_behalf_of, :permissions, to: :model
    include HydraEditor::Form::Permissions

    # TODO: remove this when https://github.com/projecthydra/hydra-editor/pull/115
    # is merged and hydra-editor 3.0.0 is released
    delegate :model_name, to: :model

    attr_reader :agreement_accepted

    self.terms += [:collection_ids, :admin_set_id]
    self.required_fields = [:title, :creator, :keyword, :rights]

    def initialize(model, current_ability)
      @agreement_accepted = !model.new_record?
      super
    end

    def [](key)
      return model.in_collection_ids if key == :collection_ids
      super
    end

    # Fields that are automatically drawn on the page above the fold
    def primary_terms
      required_fields + [:admin_set_id]
    end

    # Fields that are automatically drawn on the page below the fold
    def secondary_terms
      terms - primary_terms -
        [:files, :visibility_during_embargo, :embargo_release_date,
         :visibility_after_embargo, :visibility_during_lease,
         :lease_expiration_date, :visibility_after_lease, :visibility,
         :thumbnail_id, :representative_id, :ordered_member_ids,
         :collection_ids, :in_works_ids]
    end

    # The ordered_members which are FileSet types
    # @return [Array] All of the file sets in the ordered_members
    def ordered_fileset_members
      model.ordered_members.to_a.select { |m| m.model_name.singular.to_sym == :file_set }
    end

    # The ordered_members which are not FileSet types
    # @return [Array] All of the non file sets in the ordered_members
    def ordered_work_members
      model.ordered_members.to_a.select { |m| m.model_name.singular.to_sym != :file_set }
    end

    def self.multiple?(term)
      return true if [:rights, :collection_ids].include? term
      super
    end

    def self.build_permitted_params
      super + [:on_behalf_of, { collection_ids: [] }]
    end
  end
end
