module Hyrax::Forms
  class FileSetEditForm
    include HydraEditor::Form
    include HydraEditor::Form::Permissions

    delegate :depositor, :permissions, to: :model

    self.required_fields = [:title, :creator, :keyword, :rights]

    self.model_class = ::FileSet

    self.terms = [:resource_type, :title, :creator, :contributor, :description,
                  :keyword, :rights, :publisher, :date_created, :subject, :language,
                  :identifier, :based_near, :related_url,
                  :visibility_during_embargo, :visibility_after_embargo, :embargo_release_date,
                  :visibility_during_lease, :visibility_after_lease, :lease_expiration_date,
                  :visibility]
  end
end
