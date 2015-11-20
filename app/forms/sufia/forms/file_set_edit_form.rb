module Sufia::Forms
  class FileSetEditForm < CurationConcerns::Forms::FileSetEditForm
    include HydraEditor::Form::Permissions

    delegate :depositor, :permissions,  to: :model
  end
end
