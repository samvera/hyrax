# frozen_string_literal: true

RSpec.describe 'hyrax/base/edit.html.erb', type: :view do
  let(:work) { stub_model(GenericWork, id: '456', title: ["A nice work"]) }
  let(:ability) { double }
  let(:controller_class) { Hyrax::GenericWorksController }
  let(:form) { Hyrax.config.disable_wings ? Hyrax::Forms::ResourceForm.for(resource: work) : Hyrax::GenericWorkForm.new(work, ability, controller) }

  before do
    allow(view).to receive(:curation_concern).and_return(work)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    assign(:form, form)
    view.controller = controller_class.new
    view.controller.action_name = 'edit'
    stub_template "hyrax/base/_form.html.erb" => 'a form'
  end

  it "sets a header and draws the form" do
    expect(view).to receive(:provide).with(:page_title, "A nice work // Generic Work [456] // #{I18n.t('hyrax.product_name')}")
    expect(view).to receive(:provide).with(:page_header).and_yield
    render
    expect(rendered).to eq "  <h1><span class=\"fa fa-edit\" aria-hidden=\"true\"></span>Edit Work</h1>\n\na form\n"
  end

  context 'with a change_set style form' do
    let(:form) { Hyrax::Forms::ResourceForm.for(work) }
    let(:work) { valkyrie_create(:hyrax_work, title: 'comet in moominland') }
    let(:controller_class) { Hyrax::MonographsController }

    it "sets a header and draws the form" do
      expect(view).to receive(:provide).with(:page_title, "comet in moominland // #{work.human_readable_type} [#{work.id}] // #{I18n.t('hyrax.product_name')}")
      expect(view).to receive(:provide).with(:page_header).and_yield
      render
      expect(rendered).to eq "  <h1><span class=\"fa fa-edit\" aria-hidden=\"true\"></span>Edit Work</h1>\n\na form\n"
    end
  end
end
