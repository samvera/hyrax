require 'spec_helper'

describe 'curation_concerns/base/_show_actions.html.erb', type: :view do
  let(:presenter) { Sufia::WorkShowPresenter.new(solr_document, ability) }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:attributes) { work.to_solr }
  let(:ability) { double }
  let(:work) { create(:work, id: "123", title: ["Parent"]) }
  let(:member) { Sufia::WorkShowPresenter.new(member_document, ability) }
  let(:member_document) { SolrDocument.new(member_attributes) }
  let(:member_attributes) { member_work.to_solr }
  let(:member_work) { create(:generic_work, id: "work", title: ["Child Work"]) }
  let(:file_member) { Sufia::FileSetPresenter.new(file_document, ability) }
  let(:file_document) { SolrDocument.new(file_attributes) }
  let(:file_attributes) { file.to_solr }
  let(:file) { create(:file_set, id: 'file') }

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
      it "does not show file manager link" do
        expect(rendered).not_to have_link 'File Manager'
      end
      it "shows edit / delete links" do
        expect(rendered).to have_link 'Edit'
        expect(rendered).to have_link 'Delete'
      end
    end
    context "when the work contains 1 child" do
      before do
        allow(presenter).to receive(:member_presenters).and_return([member])
        render 'curation_concerns/base/show_actions.html.erb', presenter: presenter
      end
      it "does not show file manager link" do
        expect(rendered).not_to have_link 'File Manager'
      end
    end
    context "when the work contains 2 children" do
      before do
        allow(presenter).to receive(:member_presenters).and_return([member, file_member])
        render 'curation_concerns/base/show_actions.html.erb', presenter: presenter
      end
      it "shows file manager link" do
        expect(rendered).to have_link 'File Manager'
      end
    end
  end
end
