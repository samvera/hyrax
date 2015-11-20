module Sufia::Forms
  class FileSetEditForm < CurationConcerns::Forms::FileSetEditForm
    include HydraEditor::Form::Permissions
  end
end
