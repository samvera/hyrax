# frozen_string_literal: true

RSpec.describe 'hyrax/file_sets/_metadata.html.erb', type: :view do
  let(:doc) do
    {
      'has_model_ssim' => ['FileSet'],
      :id => '123',
      'creator_tesim' => ['Jane Smith'],
      'keyword_tesim' => ['cats', 'dogs'],
      'license_tesim' => ['https://creativecommons.org/licenses/by/4.0/']
    }
  end
  let(:solr_doc) { SolrDocument.new(doc) }
  let(:ability) { double }
  let(:presenter) { Hyrax::FileSetPresenter.new(solr_doc, ability) }

  before do
    assign(:presenter, presenter)
  end

  context 'when not using flexible metadata' do
    before do
      allow(Hyrax.config).to receive(:flexible?).and_return(false)
      render
    end

    it 'renders creator' do
      expect(rendered).to have_selector('dd', text: 'Jane Smith')
    end

    it 'renders multiple keyword values joined' do
      expect(rendered).to have_selector('dd', text: 'cats, dogs')
    end

    it 'renders license as a link' do
      expect(rendered).to have_selector('dd a[href="https://creativecommons.org/licenses/by/4.0/"]')
    end
  end

  context 'when using flexible metadata' do
    before do
      allow(Hyrax.config).to receive(:flexible?).and_return(true)
      allow(view).to receive(:view_options_for).and_return(
        {
          creator: { 'display_label' => { 'en' => 'Creator', 'default' => 'Creator' } },
          keyword: { 'display_label' => { 'en' => 'Keyword', 'default' => 'Keyword' } },
          license: { 'display_label' => { 'en' => 'License', 'default' => 'License' } }
        }
      )
      render
    end

    it 'renders creator from flexible schema' do
      expect(rendered).to have_selector('dd', text: 'Jane Smith')
    end

    it 'renders multiple keyword values joined' do
      expect(rendered).to have_selector('dd', text: 'cats, dogs')
    end

    it 'renders license as a link' do
      expect(rendered).to have_selector('dd a[href="https://creativecommons.org/licenses/by/4.0/"]')
    end
  end
end
