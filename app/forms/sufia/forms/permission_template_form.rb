module Sufia
  module Forms
    class PermissionTemplateForm
      include HydraEditor::Form
      self.model_class = PermissionTemplate
      self.terms = []
      delegate :access_grants, :access_grants_attributes=, to: :model
    end
  end
end
