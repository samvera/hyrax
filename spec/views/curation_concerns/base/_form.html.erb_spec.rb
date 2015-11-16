require 'spec_helper'

describe 'curation_concerns/base/_form.html.erb', :no_clean do
  describe 'when the file has two or more resource types' do
    let(:work) do
      stub_model(GenericWork, id: '456')
    end
    let(:ability) { double }

    let(:form) do
      CurationConcerns::GenericWorkForm.new(work, ability)
    end

    before do
      view.lookup_context.view_paths.push 'app/views/curation_concerns'
      allow(view).to receive(:curation_concern).and_return(work)
      allow(controller).to receive(:current_user).and_return(stub_model(User))
      assign(:form, form)
    end

    let(:page) do
      render
      Capybara::Node::Simple.new(rendered)
    end

    it "only draws one resource_type multiselect" do
      expect(page).to have_selector("select#file_set_resource_type", count: 1)
    end
  end
end
