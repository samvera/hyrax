RSpec.describe "hyrax/admin/admin_sets/show.html.erb", type: :view do
  let(:solr_document) { SolrDocument.new }
  let(:ability) { double }
  let(:presenter) { Hyrax::AdminSetPresenter.new(solr_document, ability) }
  before do
    # Stub route because view specs don't handle engine routes
    allow(view).to receive(:edit_admin_admin_set_path).and_return("/admin/admin_sets/123/edit")
    allow(view).to receive(:admin_admin_set_path).and_return("/admin/admin_sets/123")

    stub_template '_collection_description.html.erb' => ''
    stub_template '_show_descriptions.erb' => ''
    stub_template '_sort_and_per_page.html.erb' => 'sort and per page'
    stub_template '_document_list.html.erb' => 'document list'
    stub_template '_paginate.html.erb' => 'paginate'

    assign(:presenter, presenter)
  end

  context "when presenter has delete disabled" do
    before do
      allow(presenter).to receive(:disable_delete?).and_return(true)
      render
    end
    it "displays a disabled delete button" do
      expect(rendered).to have_selector(:css, "a.btn-danger.disabled")
    end
  end

  context "with empty admin set" do
    before do
      render
    end
    it "displays an enabled delete button" do
      expect(rendered).to have_selector(:css, "a.btn-danger")
      expect(rendered).not_to have_selector(:css, "a.btn-danger.disabled")
    end
  end

  context "with default admin set" do
    before do
      allow(presenter).to receive(:disable_delete?).and_return(true)
      render
    end
    it "displays a disabled delete button" do
      expect(rendered).to have_selector(:css, "a.btn-danger.disabled")
    end
  end
end
