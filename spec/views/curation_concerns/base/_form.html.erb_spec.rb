require 'spec_helper'

describe 'curation_concerns/base/_form.html.erb', :no_clean do
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

  describe "the form element" do
    context "with GenericWorkForm" do
      context "for a new object" do
        let(:work) { GenericWork.new }
        it "routes to the GenericWorkController" do
          expect(page).to have_selector("form[action='/concern/generic_works']")
        end
      end

      context "for a persited object" do
        it "routes to the GenericWorkController" do
          expect(page).to have_selector("form[action='/concern/generic_works/456']")
        end
      end
    end
  end

  describe 'when the work has two or more resource types' do
    it "only draws one resource_type multiselect" do
      expect(page).to have_selector("select#generic_work_resource_type", count: 1)
    end
  end

  it "renders the link for the Cancel button" do
    expect(page).to have_link("Cancel", "/")
  end
end
