require 'spec_helper'

RSpec.describe "curation_concerns/base/file_manager.html.erb" do
  let(:members) { [file_set] }
  let(:file_set) { CurationConcerns::FileSetPresenter.new(solr_doc, nil) }
  let(:solr_doc) do
    SolrDocument.new(
      resource.to_solr.merge(
        id: "test",
        title_tesim: "Test",
        thumbnail_path_ss: "/test/image/path.jpg",
        label_tesim: "file_name.tif"
      )
    )
  end
  let(:resource) { FactoryGirl.build(:file_set) }

  let(:parent) { FactoryGirl.build(:generic_work) }
  let(:parent_solr_doc) do
    SolrDocument.new(parent.to_solr.merge(id: "resource"), nil)
  end
  let(:parent_presenter) do
    CurationConcerns::WorkShowPresenter.new(parent_solr_doc, nil)
  end

  let(:blacklight_config) { CatalogController.new.blacklight_config }

  before do
    allow(parent_presenter).to receive(:file_presenters).and_return([file_set])
    assign(:presenter, parent_presenter)
    # Blacklight nonsense
    allow(view).to receive(:dom_class) { '' }
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:blacklight_configuration_context).and_return(CatalogController.new.send(:blacklight_configuration_context))
    allow(view).to receive(:search_session).and_return({})
    allow(view).to receive(:current_search_session).and_return(nil)
    allow(view).to receive(:curation_concern).and_return(parent)
    render
  end

  it "has a bulk edit header" do
    expect(rendered).to include "<h1>#{I18n.t('file_manager.link_text')}</h1>"
  end

  it "displays each file set's label" do
    expect(rendered).to have_selector "input[name='file_set[title][]'][type='text'][value='#{file_set}']"
  end

  it "displays each file set's file name" do
    expect(rendered).to have_content "file_name.tif"
  end

  it "has a link to edit each file set" do
    expect(rendered).to have_selector('a[href="/concern/file_sets/test"]')
  end

  it "has a link back to parent" do
    expect(rendered).to have_link "Test title", href: curation_concerns_generic_work_path(id: "resource")
  end

  it "has thumbnails for each resource" do
    expect(rendered).to have_selector("img[src='/test/image/path.jpg']")
  end

  it "renders a form for each member" do
    expect(rendered).to have_selector("form", count: members.length)
  end

  it "renders an input for titles" do
    expect(rendered).to have_selector("input[name='file_set[title][]']")
  end
end
