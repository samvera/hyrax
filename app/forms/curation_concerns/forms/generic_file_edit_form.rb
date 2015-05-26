module CurationConcerns
  module Forms
    class GenericFileEditForm < GenericFilePresenter
      include HydraEditor::Form
      include HydraEditor::Form::Permissions
      self.required_fields = [:title, :creator, :tag, :rights]

      # def self.build_permitted_params
      #   super.merge {
      # :visibility, :visibility_during_embargo, :embargo_release_date, :visibility_after_embargo, :visibility_during_lease, :lease_expiration_date, :visibility_after_lease }
      # end
    end
  end
end

