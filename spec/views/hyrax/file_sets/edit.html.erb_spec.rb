# frozen_string_literal: true

RSpec.describe 'hyrax/file_sets/edit.html.erb', type: :view do
  let(:ability)  { Ability.new(user) }
  let(:file_set) { stub_model(FileSet) }
  let(:parent)   { stub_model(GenericWork) }
  let(:form)     { Hyrax::Forms::FileSetEditForm.new(file_set) }
  let(:user)     { FactoryBot.build(:user) }
  let(:versions) { [] }

  before do
    allow(controller).to receive(:current_ability).and_return(ability)
    allow(view).to receive(:curation_concern).and_return(file_set)
    allow(view).to receive(:form).and_return(form)
    assign(:version_list, versions)

    stub_template "hyrax/file_sets/_form.html.erb" => "Form for File Set"
    stub_template "hyrax/file_sets/_permission.html.erb" => "Permissions for File Set"
  end

  it 'renders the page without preview by default' do
    render

    expect(rendered).to include "No preview available"
  end
end
