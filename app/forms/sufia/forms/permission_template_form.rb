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
    end
  end
end
