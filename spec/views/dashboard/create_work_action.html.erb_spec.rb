require 'spec_helper'

RSpec.describe 'dashboard/_create_work_action.html.erb', type: :view do
  before do
    allow(view).to receive(:create_work_presenter).and_return(presenter)
    allow(presenter).to receive(:first_model).and_yield(GenericWork)
    render
  end

  context "when we have more than one model" do
    let(:presenter) { instance_double(Sufia::SelectTypeListPresenter, many?: true) }

    it "renders the select template" do
      expect(rendered).to have_selector 'a[data-toggle="modal"][data-target="#worktypes-to-create"]'
      expect(rendered).to have_link('Create Work', href: '#')
    end
  end

  context "when we have one model" do
    let(:presenter) { instance_double(Sufia::SelectTypeListPresenter, many?: false) }

    it "doesn't draw the modal" do
      expect(rendered).not_to include "modal"
      expect(rendered).to have_link "Create Work", href: '/concern/generic_works/new'
    end
  end
end
