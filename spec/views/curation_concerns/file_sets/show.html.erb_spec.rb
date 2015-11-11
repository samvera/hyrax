require 'spec_helper'

describe 'curation_concerns/file_sets/show.html.erb', type: :view do
  before do
    allow(view).to receive(:parent).and_return(parent)
  end

  let(:parent) { stub_model(GenericWork) }

  let(:depositor) do
    stub_model(User,
               user_key: 'bob',
               twitter_handle: 'bot4lib')
  end

  let(:content) do
    double('content', versions: [], mimeType: 'application/pdf')
  end

  let(:file_set) do
    stub_model(FileSet, id: '123',
                        depositor: depositor.user_key,
                        audit_stat: 1,
                        title: ['My Title'],
                        description: ['Lorem ipsum lorem ipsum. http://my.link.com']
              )
  end

  let(:ability) { double }
  let(:solr_doc) { SolrDocument.new(file_set.to_solr) }
  let(:presenter) { CurationConcerns::FileSetPresenter.new(solr_doc, ability) }

  before do
    view.lookup_context.view_paths.push CurationConcerns::Engine.root + 'app/views/curation_concerns/base'
    allow(view).to receive(:can?).with(:edit, String).and_return(true)
    assign(:presenter, presenter)
  end

  describe 'title heading' do
    before do
      stub_template 'shared/_title_bar.html.erb' => 'Title Bar'
      render template: 'curation_concerns/file_sets/show.html.erb', layout: 'layouts/curation_concerns'
    end
    it 'shows the title' do
      expect(rendered).to have_selector 'h1 > small', text: 'My Title'
    end
  end

  describe 'attributes' do
    before { render }

    it 'shows the description' do
      expect(rendered).to have_selector '.attribute.description', text: 'Lorem ipsum'
    end
  end
end
