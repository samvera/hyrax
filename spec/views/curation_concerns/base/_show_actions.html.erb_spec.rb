require 'spec_helper'

describe 'curation_concerns/base/show_actions' do
  let(:model) { double('model', persisted?: true, to_param: '123', model_name: GenericWork.model_name) }
  let(:presenter) { double("presenter", human_readable_type: 'Image', id: '123', to_model: model, valid_child_concerns: [GenericWork]) }

  before do
    assign(:presenter, presenter)
    allow(view).to receive(:collection_options_for_select)
    render 'curation_concerns/base/show_actions.html.erb', collector: collector, editor: editor
  end

  context "as a collector" do
    let(:editor) { true }
    let(:collector) { true }
    it "shows the add to collection link" do
      expect(rendered).not_to have_link 'Add to a Collection'
    end
  end

  context "as an editor" do
    let(:editor) { true }
    let(:collector) { true }
    context "when there are valid_child_concerns" do
      it "creates a link" do
        expect(rendered).to have_link 'Attach Generic Work', href: "/concern/parent/#{presenter.id}/generic_works/new"
      end
    end
  end
end
