RSpec.describe 'hyrax/my/works/_list_works.html.erb', type: :view do
  let(:id) { "3197z511f" }
  let(:work_data) do
    {
      id: id,
      "has_model_ssim" => ["GenericWork"],
      "title_tesim" => ["Work Title"]
    }
  end

  let(:doc) { SolrDocument.new(work_data) }
  let(:collection) { mock_model(Collection) }
  let(:presenter) { Hyrax::WorkShowPresenter.new(doc, nil) }

  before do
    allow(view).to receive(:current_user).and_return(stub_model(User))
    allow(view).to receive(:render_collection_links).with(doc).and_return("<a href=\"collection/1\">Collection Title</a>".html_safe)
    allow(view).to receive(:render_visibility_link).with(doc).and_return("<a class=\"visibility-link\">Private</a>".html_safe)
    stub_template 'hyrax/my/works/_work_action_menu.html.erb' => 'actions'
    render 'hyrax/my/works/list_works', document: doc, presenter: presenter
  end

  it 'the line item displays the work and its actions' do
    expect(rendered).to have_selector("tr#document_#{id}")
    expect(rendered).to have_link 'Work Title', href: hyrax_generic_work_path(id)
    expect(rendered).to have_content 'actions'
    expect(rendered).to have_css 'a.visibility-link', text: 'Private'
    expect(rendered).to have_link 'Collection Title', href: 'collection/1'
  end
end
