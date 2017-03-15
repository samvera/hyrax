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
      required_fields
    end

    # Fields that are automatically drawn on the page below the fold
    def secondary_terms
      terms - primary_terms -
        [:files, :visibility_during_embargo, :embargo_release_date,
         :visibility_after_embargo, :visibility_during_lease,
         :lease_expiration_date, :visibility_after_lease, :visibility,
         :thumbnail_id, :representative_id, :ordered_member_ids,
         :collection_ids, :in_works_ids, :admin_set_id]
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

    # The in_work items
    # @return [Array] All of the works that this work is a member of
    def in_work_members
      model.in_works.to_a
    end

    def self.multiple?(term)
      return true if [:rights, :collection_ids].include? term
      super
    end

    def self.sanitize_params(form_params)
      admin_set_id = form_params[:admin_set_id]
      if admin_set_id && Sipity::Workflow.find_by!(name: Sufia::PermissionTemplate.find_by!(admin_set_id: admin_set_id).workflow_name).allows_access_grant?
        return super
      end
      params_without_permissions = permitted_params.reject { |arg| arg.respond_to?(:key?) && arg.key?(:permissions_attributes) }
      form_params.permit(*params_without_permissions)
    end

    def self.build_permitted_params
      super + [:on_behalf_of, { collection_ids: [] }]
    end
  end
end
