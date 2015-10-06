module CurationConcerns
  module Forms
    class FileSetEditForm
      include HydraEditor::Form
      include HydraEditor::Form::Permissions
      self.required_fields = [:title, :creator, :tag, :rights]

      self.model_class = ::FileSet

      self.terms = [:resource_type, :title, :creator, :contributor, :description, :tag, :rights,
                    :publisher, :date_created, :subject, :language, :identifier, :based_near, :related_url]
    end
  end
end
