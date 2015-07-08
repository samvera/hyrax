module CurationConcerns
  module Forms
    class GenericWorkEditForm < GenericWorkPresenter
      include HydraEditor::Form
      include HydraEditor::Form::Permissions
      self.required_fields = [:title, :creator, :tag, :rights]
    end
  end
end
