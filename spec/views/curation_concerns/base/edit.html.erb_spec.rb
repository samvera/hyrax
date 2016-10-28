require 'spec_helper'

describe 'curation_concerns/base/edit.html.erb', type: :view do
  let(:work) { stub_model(GenericWork, id: '456', title: ["A nice work"]) }
  let(:ability) { double }

  let(:form) do
    CurationConcerns::GenericWorkForm.new(work, ability)
  end

  before do
    view.lookup_context.view_paths.push 'app/views/curation_concerns'
    allow(view).to receive(:curation_concern).and_return(work)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    assign(:form, form)
    view.controller = CurationConcerns::GenericWorksController.new
    view.controller.action_name = 'edit'
    stub_template "curation_concerns/base/_form.html.erb" => 'a form'
  end

  it "sets a header and draws the form" do
    expect(view).to receive(:provide).with(:page_title, 'A nice work // Generic Work [456] // Sufia')
    expect(view).to receive(:provide).with(:page_header).and_yield
    render
    expect(rendered).to eq "  <h1>Edit Work</h1>\n\na form\n"
  end
end
