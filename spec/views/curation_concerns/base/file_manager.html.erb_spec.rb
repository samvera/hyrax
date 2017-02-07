require 'spec_helper'

RSpec.describe "curation_concerns/base/file_manager.html.erb" do
  let(:members) { [file_set, member] }
  let(:file_set) { CurationConcerns::FileSetPresenter.new(solr_doc, nil) }
  let(:member) { CurationConcerns::WorkShowPresenter.new(solr_doc_work, nil) }
  let(:solr_doc) do
    SolrDocument.new(
      resource.to_solr.merge(
        id: "test",
        title_tesim: "Test",
        thumbnail_path_ss: "/test/image/path.jpg",
        label_tesim: ["file_name.tif"]
      )
    )
  end
  let(:solr_doc_work) do
    SolrDocument.new(
      resource.to_solr.merge(
        id: "work",
        title_tesim: "Work",
        thumbnail_path_ss: "/test/image/path.jpg",
        label_tesim: ["work"]
      )
    )
  end
  let(:resource) { FactoryGirl.build(:file_set) }

  let(:parent) { build(:generic_work) }

  let(:form) do
    CurationConcerns::Forms::FileManagerForm.new(parent, nil)
  end

  let(:blacklight_config) { CatalogController.new.blacklight_config }

  before do
    allow(parent).to receive(:etag).and_return("123456")
    allow(parent).to receive(:persisted?).and_return(true)
    allow(parent).to receive(:id).and_return('resource')

    allow(form).to receive(:member_presenters).and_return([file_set, member])
    assign(:form, form)
    # Blacklight nonsense
    allow(view).to receive(:dom_class) { '' }
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:blacklight_configuration_context).and_return(CatalogController.new.send(:blacklight_configuration_context))
    allow(view).to receive(:search_session).and_return({})
    allow(view).to receive(:current_search_session).and_return(nil)
    allow(view).to receive(:curation_concern).and_return(parent)
    allow(view).to receive(:contextual_path).with(anything, anything) do |x, y|
      CurationConcerns::ContextualPath.new(x, y).show
    end
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
    expect(rendered).to have_selector("#sortable form", count: members.length)
  end

  it "renders an input for titles" do
    expect(rendered).to have_selector("input[name='file_set[title][]']")
  end

  it "renders a resource form for the entire resource" do
    expect(rendered).to have_selector("form#resource-form")
  end

  it "renders a hidden field for the resource form thumbnail id" do
    expect(rendered).to have_selector("#resource-form input[type=hidden][name='generic_work[thumbnail_id]']", visible: false)
  end

  it "renders a thumbnail field for each member" do
    expect(rendered).to have_selector("input[name='thumbnail_id']", count: members.length)
  end

  it "renders a hidden field for the resource form representative id" do
    expect(rendered).to have_selector("#resource-form input[type=hidden][name='generic_work[representative_id]']", visible: false)
  end

  it "renders a representative field for each member" do
    expect(rendered).to have_selector("input[name='representative_id']", count: members.length)
  end
end
