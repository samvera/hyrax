require 'spec_helper'

describe 'curation_concerns/base/_form.html.erb' do
  let(:work) do
    stub_model(GenericWork, id: '456')
  end
  let(:ability) { double }

  let(:form) do
    CurationConcerns::GenericWorkForm.new(work, ability)
  end

  before do
    view.lookup_context.view_paths.push 'app/views/curation_concerns'
    allow(work).to receive(:member_ids).and_return([1, 2])
    allow(view).to receive(:curation_concern).and_return(work)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    assign(:form, form)
  end

  let(:page) do
    render
    Capybara::Node::Simple.new(rendered)
  end

  context "for a new object" do
    let(:work) { GenericWork.new }
    it "routes to the GenericWorkController" do
      expect(page).to have_selector("form[action='/concern/generic_works']")
    end

    it "has a switch to Batch Upload link" do
      expect(page).to have_link('Batch upload')
    end
  end

  context "for a persited object" do
    it "routes to the GenericWorkController" do
      expect(page).to have_selector("form[action='/concern/generic_works/456']")
    end

    describe 'when the work has two or more resource types' do
      it "only draws one resource_type multiselect" do
        expect(page).to have_selector("select#generic_work_resource_type", count: 1)
      end
      it "allows to change the thumbnail" do
        expect(page).to have_selector("select#generic_work_thumbnail_id", count: 1)
      end
      it "allows to change the representative media" do
        expect(page).to have_selector("select#generic_work_representative_id", count: 1)
      end
    end

    it "doesn't have switch to Batch Upload link" do
      expect(page).not_to have_link('Batch upload', href: '/batch_uploads')
    end

    it "renders the link for the Cancel button" do
      expect(page).to have_link("Cancel", href: "/dashboard")
    end
  end
end
