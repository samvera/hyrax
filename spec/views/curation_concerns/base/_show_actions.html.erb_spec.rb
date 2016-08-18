require 'spec_helper'

describe 'curation_concerns/base/_show_actions.html.erb', type: :view do
  let(:ability) { double }
  let(:presenter) do
    Sufia::WorkShowPresenter.new(
      SolrDocument.new(
        id: "123",
        title_tesim: "Parent",
        has_model_ssim: ["GenericWork"]
      ),
      ability
    )
  end
  let(:member) do
    Sufia::WorkShowPresenter.new(
      SolrDocument.new(
        id: "work",
        title_tesim: "Child Work",
        has_model_ssim: ["GenericWork"]
      ),
      ability
    )
  end

  before do
    allow(ability).to receive(:can?).with(:create, FeaturedWork).and_return(false)
  end

  context "as an unregistered user" do
    before do
      allow(presenter).to receive(:editor?).and_return(false)
      render 'curation_concerns/base/show_actions.html.erb', presenter: presenter
    end
    it "doesn't show edit / delete links" do
      expect(rendered).not_to have_link 'Edit'
      expect(rendered).not_to have_link 'Delete'
    end
  end

  context "as an editor" do
    before do
      allow(presenter).to receive(:editor?).and_return(true)
    end
    context "when the work does not contain children" do
      before do
        allow(presenter).to receive(:member_presenters).and_return([])
        render 'curation_concerns/base/show_actions.html.erb', presenter: presenter
      end
      it "shows file manager link" do
        expect(rendered).not_to have_link 'File Manager'
      end
      it "shows edit / delete links" do
        expect(rendered).to have_link 'Edit'
        expect(rendered).to have_link 'Delete'
      end
    end
    context "when the work contains children" do
      before do
        allow(presenter).to receive(:member_presenters).and_return([member])
        render 'curation_concerns/base/show_actions.html.erb', presenter: presenter
      end
      before { allow(presenter).to receive(:member_presenters).and_return([member]) }
      it "shows file manager link" do
        expect(rendered).to have_link 'File Manager'
      end
    end
  end
end
