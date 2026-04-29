# frozen_string_literal: true

RSpec.describe 'URL redirects', type: :request do
  let(:work_id)   { 'abc-123-xyz' }
  let(:work_doc)  { { 'id' => work_id, 'has_model_ssim' => ['GenericWork'] } }

  before { Rails.cache.clear }

  context 'with both gates open (config + Flipflop)' do
    before do
      allow(Hyrax.config).to receive(:redirects_enabled?).and_return(true)
      allow(Flipflop).to receive(:redirects?).and_return(true)
      allow(Hyrax::SolrService)
        .to receive(:get)
        .with('redirects_path_ssim:"/handle/12345/678"', rows: 1)
        .and_return('response' => { 'docs' => [work_doc] })
    end

    it 'resolves a registered alias path to a 301 with the permanent URL Location' do
      get '/handle/12345/678'
      expect(response.code).to eq('301')
      expect(response.headers['Location']).to include("/concern/generic_works/#{work_id}")
    end

    context 'when no redirect matches' do
      before do
        allow(Hyrax::SolrService)
          .to receive(:get)
          .with('redirects_path_ssim:"/no-such-path"', rows: 1)
          .and_return('response' => { 'docs' => [] })
      end

      it 'returns 404' do
        get '/no-such-path'
        expect(response.code).to eq('404')
      end
    end
  end

  context 'with the config on but the Flipflop off' do
    before do
      allow(Hyrax.config).to receive(:redirects_enabled?).and_return(true)
      allow(Flipflop).to receive(:redirects?).and_return(false)
    end

    it 'does not consult Solr for unmatched paths' do
      expect(Hyrax::SolrService).not_to receive(:get)
      get '/handle/12345/678'
      expect(response.code).to eq('404')
    end
  end

  context 'with the config off' do
    before do
      allow(Hyrax.config).to receive(:redirects_enabled?).and_return(false)
    end

    it 'does not consult Flipflop or Solr (config short-circuits)' do
      expect(Flipflop).not_to receive(:redirects?)
      expect(Hyrax::SolrService).not_to receive(:get)
      get '/handle/12345/678'
      expect(response.code).to eq('404')
    end
  end
end
