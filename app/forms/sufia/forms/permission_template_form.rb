module Sufia
  module Forms
    class PermissionTemplateForm
      include HydraEditor::Form
      self.model_class = PermissionTemplate
      self.terms = []
      delegate :access_grants, :access_grants_attributes=, :visibility, to: :model

      # Visibility options for permission templates
      def visibility_options
        i18n_prefix = "sufia.admin.admin_sets.form_visibility.visibility"
        # Note: Visibility 'varies' = '' implies no constraints
        [[Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC, I18n.t('.everyone', scope: i18n_prefix)],
         ['', I18n.t('.varies', scope: i18n_prefix)],
         [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED, I18n.t('.institution', scope: i18n_prefix)],
         [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, I18n.t('.restricted', scope: i18n_prefix)]]
      end

      def update(attributes)
        manage_grants = attributes[:access_grants_attributes].select { |x| x[:access] == 'manage' }
        grant_admin_set_access(manage_grants) if manage_grants.present?
        model.update(attributes)
      end

      private

        def grant_admin_set_access(manage_grants)
          admin_set = AdminSet.find(model.admin_set_id)
          admin_set.edit_users = manage_grants.select { |x| x[:agent_type] == 'user' }.map { |x| x[:agent_id] }
          admin_set.edit_groups = manage_grants.select { |x| x[:agent_type] == 'group' }.map { |x| x[:agent_id] }
          admin_set.save!
        end
    end
  end
end
