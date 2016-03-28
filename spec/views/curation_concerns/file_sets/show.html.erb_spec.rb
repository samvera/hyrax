require 'spec_helper'

describe 'curation_concerns/file_sets/show.html.erb', type: :view do
  let(:parent) { stub_model(GenericWork) }
  let(:user) { double(user_key: 'sarah', twitter_handle: 'test') }
  let(:file_set) { build(:file_set, id: '123', depositor: user.user_key, title: ['My Title'], user: user, visibility: 'open') }
  let(:ability) { double }
  let(:solr_doc) { SolrDocument.new(file_set.to_solr) }
  let(:presenter) { Sufia::FileSetPresenter.new(solr_doc, ability) }
  let(:mock_metadata) do
    {
      format: ["Tape"],
      long_term: ["x" * 255],
      multi_term: ["1", "2", "3", "4", "5", "6", "7", "8"],
      string_term: 'oops, I used a string instead of an array',
      logged_audit_status: "Audits have not yet been run on this file"
    }
  end
  before do
    allow(view).to receive(:parent).and_return(parent)
    view.lookup_context.prefixes.push 'curation_concerns/base'
    allow(view).to receive(:can?).with(:edit, SolrDocument).and_return(false)
    allow(ability).to receive(:can?).with(:edit, SolrDocument).and_return(false)
    allow(presenter).to receive(:audit_status).and_return(mock_metadata)
    assign(:presenter, presenter)
    assign(:document, solr_doc)
    assign(:audit_status, "none")
  end

  describe 'title heading' do
    before do
      stub_template 'shared/_title_bar.html.erb' => 'Title Bar'
      stub_template 'shared/_citations.html.erb' => 'Citation'
      render template: 'curation_concerns/file_sets/show.html.erb', layout: 'layouts/curation_concerns'
    end
    it 'shows the title' do
      expect(rendered).to have_selector 'h1', text: 'My Title'
    end
  end
end
