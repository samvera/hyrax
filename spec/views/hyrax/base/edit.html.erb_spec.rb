RSpec.describe 'hyrax/base/edit.html.erb', type: :view do
  let(:work) { stub_model(GenericWork, id: '456', title: ["A nice work"]) }

  let(:change_set) do
    Hyrax::GenericWorkChangeSet.new(work)
  end

  before do
    allow(view).to receive(:curation_concern).and_return(work)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    assign(:change_set, change_set)
    view.controller = Hyrax::GenericWorksController.new
    view.controller.action_name = 'edit'
    stub_template "hyrax/base/_form.html.erb" => 'a form'
  end

  it "sets a header and draws the form" do
    expect(view).to receive(:provide).with(:page_title, 'A nice work // Generic Work [456] // Hyrax')
    expect(view).to receive(:provide).with(:page_header).and_yield
    render
    expect(rendered).to eq "  <h1><span class=\"fa fa-edit\"></span>Edit Work</h1>\n\na form\n"
  end
end
