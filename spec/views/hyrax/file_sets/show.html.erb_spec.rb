# frozen_string_literal: true
RSpec.describe 'hyrax/file_sets/show.html.erb', type: :view do
  let(:user) { double(user_key: 'sarah', twitter_handle: 'test') }
  let(:ability) { double }
  let(:doc) do
    {
      "has_model_ssim" => ["FileSet"],
      :id => "123",
      "title_tesim" => ["My Title"]
    }
  end
  let(:solr_doc) { SolrDocument.new(doc) }
  let(:presenter) { Hyrax::FileSetPresenter.new(solr_doc, ability) }
  let(:mock_metadata) do
    {
      format: ["Tape"],
      long_term: ["x" * 255],
      multi_term: ["1", "2", "3", "4", "5", "6", "7", "8"],
      string_term: 'oops, I used a string instead of an array',
      logged_fixity_status: "Fixity checks have not yet been run on this file"
    }
  end
  let(:work_solr_document) do
    SolrDocument.new(id: '900', title_tesim: ['My Title'])
  end
  let(:parent_presenter) { Hyrax::WorkShowPresenter.new(work_solr_document, ability) }

  before do
    view.lookup_context.prefixes.push 'hyrax/base'
    allow(view).to receive(:can?).with(:edit, Hyrax::SolrDocument::OrderedMembers).and_return(false)
    allow(ability).to receive(:can?).with(:edit, Hyrax::SolrDocument::OrderedMembers).and_return(false)
    allow(view).to receive(:can?).with(:edit, SolrDocument).and_return(false)
    allow(ability).to receive(:can?).with(:edit, SolrDocument).and_return(false)
    allow(presenter).to receive(:fixity_status).and_return(mock_metadata)
    assign(:presenter, presenter)
    assign(:parent_presenter, parent_presenter)
    allow(presenter).to receive(:parent_presenter).and_return parent_presenter
    assign(:document, solr_doc)
    assign(:fixity_status, "none")
  end

  describe 'title heading' do
    before do
      stub_template 'shared/_title_bar.html.erb' => 'Title Bar'
      stub_template 'shared/_citations.html.erb' => 'Citation'
      render
    end
    it 'shows the title' do
      expect(rendered).to have_selector 'h1', text: 'My Title'
    end
  end

  it "does not render single-use links" do
    expect(rendered).not_to have_selector('table.single-use-links')
  end
end
