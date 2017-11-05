RSpec.describe "hyrax/base/file_manager.html.erb" do
  let(:members) { [file_set, member] }
  let(:file_set) { Hyrax::FileSetPresenter.new(solr_doc, nil) }
  let(:member) { Hyrax::WorkShowPresenter.new(solr_doc_work, nil) }
  let(:solr_doc) do
    SolrDocument.new(
      resource.to_solr.merge(
        id: "test",
        title_tesim: ["Test"],
        thumbnail_path_ss: "/test/image/path.jpg",
        label_tesim: ["file_name.tif"]
      )
    )
  end
  let(:solr_doc_work) do
    SolrDocument.new(
      resource.to_solr.merge(
        id: "work",
        title_tesim: ["Work"],
        thumbnail_path_ss: "/test/image/path.jpg",
        label_tesim: ["work"]
      )
    )
  end
  let(:resource) { build(:file_set) }

  let(:parent) { build(:generic_work) }

  let(:form) do
    Hyrax::Forms::FileManagerForm.new(parent, nil)
  end

  before do
    allow(parent).to receive(:etag).and_return("123456")
    allow(parent).to receive(:persisted?).and_return(true)
    allow(parent).to receive(:id).and_return('resource')

    allow(form).to receive(:member_presenters).and_return([file_set, member])
    assign(:form, form)
    # Blacklight nonsense
    allow(view).to receive(:dom_class) { '' }
    allow(view).to receive(:search_session).and_return({})
    allow(view).to receive(:current_search_session).and_return(nil)
    allow(view).to receive(:curation_concern).and_return(parent)
    allow(view).to receive(:contextual_path).with(anything, anything) do |x, y|
      Hyrax::ContextualPath.new(x, y).show
    end
    render
  end

  it "draws the page" do
    # has a bulk edit header
    expect(rendered).to include "<h1>#{I18n.t('hyrax.file_manager.link_text')}</h1>"

    # displays each file set's label
    expect(rendered).to have_selector "input[name='file_set[title][]'][type='text'][value='#{file_set}']"

    # displays each file set's file name
    expect(rendered).to have_content "file_name.tif"

    # has a link to edit each file set
    expect(rendered).to have_selector('a[href="/concern/file_sets/test"]')

    # has a link back to parent
    expect(rendered).to have_link "Test title", href: hyrax_generic_work_path(id: "resource")

    # has thumbnails for each resource
    expect(rendered).to have_selector("img[src='/test/image/path.jpg']")

    # renders a form for each member
    expect(rendered).to have_selector("#sortable form", count: members.length)

    # renders an input for titles
    expect(rendered).to have_selector("input[name='file_set[title][]']")

    # renders a resource form for the entire resource
    expect(rendered).to have_selector("form#resource-form")

    # renders a hidden field for the resource form thumbnail id
    expect(rendered).to have_selector("#resource-form input[type=hidden][name='generic_work[thumbnail_id]']", visible: false)

    # renders a thumbnail field for each member
    expect(rendered).to have_selector("input[name='thumbnail_id']", count: members.length)

    # renders a hidden field for the resource form representative id
    expect(rendered).to have_selector("#resource-form input[type=hidden][name='generic_work[representative_id]']", visible: false)

    # renders a representative field for each member
    expect(rendered).to have_selector("input[name='representative_id']", count: members.length)
  end
end
