require 'spec_helper'

describe 'curation_concerns/base/items', type: :view do
  let(:ability) { double }
  let(:presenter) { Sufia::WorkShowPresenter.new(solr_doc, ability) }
  let(:file_set) { Sufia::FileSetPresenter.new(solr_doc_file, ability) }
  let(:member) { Sufia::WorkShowPresenter.new(solr_doc_work, ability) }
  let(:solr_doc) { double(id: '123', human_readable_type: 'Work') }
  let(:solr_doc_file) do
    SolrDocument.new(
      FactoryGirl.build(:file_set).to_solr.merge(
        id: "file",
        title_tesim: "Child File",
        label_tesim: "ChildFile.pdf"
      )
    )
  end
  let(:solr_doc_work) do
    SolrDocument.new(
      FactoryGirl.build(:generic_work).to_solr.merge(
        id: "work",
        title_tesim: "Child Work"
      )
    )
  end
  let(:blacklight_config) { CatalogController.new.blacklight_config }
  let(:blacklight_configuration_context) do
    Blacklight::Configuration::Context.new(controller)
  end

  context "when children are present" do
    before do
      stub_template 'curation_concerns/base/_actions.html.erb' => 'Actions'
      allow(presenter).to receive(:member_presenters).and_return([file_set, member])
      allow(view).to receive(:blacklight_config).and_return(Blacklight::Configuration.new)
      allow(view).to receive(:blacklight_configuration_context).and_return(blacklight_configuration_context)
      allow(view).to receive(:contextual_path).and_return("/whocares")
      allow(ability).to receive(:can?).and_return(true)
      render 'curation_concerns/base/items', presenter: presenter
    end
    it "links to child work" do
      expect(rendered).to have_link 'Child Work'
    end
    it "links to child file, using title as link text" do
      expect(rendered).not_to have_link 'ChildFile.pdf'
      expect(rendered).to have_link 'Child File'
    end
  end
end
