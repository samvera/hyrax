# frozen_string_literal: true
RSpec.describe 'hyrax/file_sets/_permission.html.erb', type: :view do
  let(:file_set) { stub_model(FileSet) }
  let(:form_object) do
    if Hyrax.config.disable_wings
      Hyrax::Forms::ResourceForm.for(resource: file_set).prepopulate!
    else
      Hyrax::Forms::FileSetEditForm.new(file_set)
    end
  end

  before do
    stub_template "hyrax/file_sets/_permission_form.html.erb" => 'a form'
    render 'hyrax/file_sets/permission', file_set: file_set, form_object: form_object
  end

  context "without additional users" do
    it "draws the permissions form without error" do
      expect(rendered).to have_css('form#permission[data-param-key="file_set"]')
    end
  end
end
