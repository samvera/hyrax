require 'spec_helper'

describe 'curation_concerns/file_sets/show.html.erb', type: :view do
  before do
    allow(view).to receive(:parent).and_return(parent)
    allow(view).to receive_messages(blacklight_config: CatalogController.blacklight_config,
                                    blacklight_configuration_context: Blacklight::Configuration::Context.new(controller))
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
                        description: ['Lorem ipsum lorem ipsum. http://my.link.com'],
                        mime_type: mime_type
              )
  end

  let(:mime_type) { 'application/binary' }
  let(:ability) { double }
  let(:solr_doc) { SolrDocument.new(file_set.to_solr) }
  let(:presenter) { CurationConcerns::FileSetPresenter.new(solr_doc, ability) }

  before do
    view.lookup_context.prefixes.push 'curation_concerns/base'
    allow(view).to receive(:can?).with(:edit, String).and_return(true)
    assign(:presenter, presenter)
  end

  describe 'title heading' do
    before do
      stub_template 'shared/_brand_bar.html.erb' => 'Brand Bar'
      stub_template 'shared/_title_bar.html.erb' => 'Title Bar'
      render template: 'curation_concerns/file_sets/show.html.erb', layout: 'layouts/curation_concerns'
    end
    it 'shows the title' do
      expect(rendered).to have_selector 'h1 > small', text: 'My Title'
    end
  end

  describe 'media display' do
    context 'when config is true' do
      before do
        allow(CurationConcerns.config).to receive(:display_media_download_link) { true }
        render
      end

      context 'with an image' do
        let(:mime_type) { 'image/tiff' }
        it 'renders the download link' do
          expect(rendered).to have_link('Download the full-sized image')
        end
      end

      context 'with a PDF' do
        let(:mime_type) { 'application/pdf' }
        it 'renders the download link' do
          expect(rendered).to have_link('Download the full-sized PDF')
        end
      end

      context 'with a word document' do
        let(:mime_type) { 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' }
        it 'renders the download link' do
          expect(rendered).to have_link('Download the document')
        end
      end

      context 'with anything else' do
        let(:mime_type) { 'application/binary' }
        it 'renders the download link' do
          expect(rendered).to have_link('Download the document')
        end
      end
    end

    context 'when config is false' do
      before do
        allow(CurationConcerns.config).to receive(:display_media_download_link) { false }
        render
      end

      context 'with an image' do
        let(:mime_type) { 'image/tiff' }
        it 'does not render the download link' do
          expect(rendered).not_to have_link('Download the full-sized image')
        end
      end

      context 'with a PDF' do
        let(:mime_type) { 'application/pdf' }
        it 'does not render the download link' do
          expect(rendered).not_to have_link('Download the full-sized PDF')
        end
      end

      context 'with a word document' do
        let(:mime_type) { 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' }
        it 'does not render the download link' do
          expect(rendered).not_to have_link('Download the document')
        end
      end

      context 'with anything else' do
        let(:mime_type) { 'application/binary' }
        it 'does not render the download link' do
          expect(rendered).not_to have_link('Download the document')
        end
      end
    end
  end

  describe 'attributes' do
    before { render }

    it 'shows the description' do
      expect(rendered).to have_selector '.attribute.description', text: 'Lorem ipsum'
    end
  end
end
