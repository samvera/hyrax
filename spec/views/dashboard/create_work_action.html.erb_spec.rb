require 'spec_helper'

RSpec.describe 'dashboard/create_work_action.html.erb', type: :view do
  let(:classification) { double }
  before do
    allow(CurationConcerns::QuickClassificationQuery).to receive(:new).and_return(classification)
    allow(view).to receive(:current_user).and_return(double)
    allow(classification).to receive(:authorized_models).and_return(results)
  end

  context "when we have more than one model" do
    let(:results) { [GenericWork, double] }
    before do
      stub_template 'dashboard/_select_work_type.html.erb' => 'SelectType'
      render 'dashboard/create_work_action', classification: classification
    end
    it "renders the select template" do
      expect(rendered).to have_content 'SelectType'
    end
  end

  context "when we have one model" do
    let(:results) { [GenericWork] }
    before do
      allow(classification).to receive(:each).and_yield(GenericWork)
      render 'dashboard/create_work_action', classification: classification
    end
    it "doesn't draw the modal" do
      expect(rendered).not_to include "modal"
      expect(rendered).to have_link "Create Work", href: '/concern/generic_works/new'
    end
  end
end
