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

    def work_members
      model.members.to_a.reject { |m| m.is_a? FileSet }
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
      super + [:on_behalf_of,
               { collection_ids: [] },
               { work_members_attributes: [:id, :_destroy] }]
    end

    # This is required so that fields_for will draw a nested form.
    # See ActionView::Helpers#nested_attributes_association?
    #   https://github.com/rails/rails/blob/v5.0.2/actionview/lib/action_view/helpers/form_helper.rb#L1890
    delegate :work_members_attributes=, to: :model
  end
end
