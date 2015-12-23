require 'spec_helper'

describe 'curation_concerns/base/show_actions' do
  let(:model) { double('model', persisted?: true, to_param: '123', model_name: GenericWork.model_name) }
  let(:presenter) { double("presenter", human_readable_type: 'Image', id: '123', to_model: model) }
  before do
    assign(:presenter, presenter)
    render 'curation_concerns/base/show_actions.html.erb', collector: collector, editor: editor
  end

  context "as a collector" do
    let(:editor) { true }
    let(:collector) { true }
    it "shows the add to collection link" do
      expect(rendered).to have_link 'Add to a Collection'
    end
  end
end
