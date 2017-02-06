describe "hyrax/admin/admin_sets/show.html.erb", type: :view do
  let(:solr_document) { SolrDocument.new(admin_set.to_solr) }
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

  context "with non-empty admin set" do
    let(:admin_set) { build(:admin_set, id: '123') }
    let(:work) { build(:work, title: ['Example Work Title']) }
    before do
      admin_set.members = [work]
      admin_set.save!
      render
    end
    it "displays a disabled delete button" do
      expect(rendered).to have_selector(:css, "a.btn-danger.disabled")
    end
  end

  context "with empty admin set" do
    let(:admin_set) { build(:admin_set, id: '345') }
    before do
      render
    end
    it "displays an enabled delete button" do
      expect(rendered).to have_selector(:css, "a.btn-danger")
      expect(rendered).not_to have_selector(:css, "a.btn-danger.disabled")
    end
  end

  context "with default admin set" do
    let(:admin_set) { build(:admin_set, id: AdminSet::DEFAULT_ID) }
    before do
      render
    end
    it "displays a disabled delete button" do
      expect(rendered).to have_selector(:css, "a.btn-danger.disabled")
    end
  end
end
