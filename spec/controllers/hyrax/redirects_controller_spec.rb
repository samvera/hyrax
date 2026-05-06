# frozen_string_literal: true

RSpec.describe Hyrax::RedirectsController, type: :controller do
  routes { Rails.application.routes }

  describe '#show' do
    let(:work_id)        { 'abc-123-xyz' }
    let(:collection_id)  { 'col-456-uvw' }
    let(:work_doc) do
      { 'id' => work_id, 'has_model_ssim' => ['GenericWork'] }
    end
    let(:collection_doc) do
      { 'id' => collection_id, 'has_model_ssim' => ['CollectionResource'] }
    end

    before do
      allow(Hyrax.config).to receive(:redirects_enabled?).and_return(true)
      allow(Flipflop).to receive(:redirects?).and_return(true)
      Rails.cache.clear
    end

    context 'with a path that resolves to a work' do
      before do
        allow(Hyrax::SolrService)
          .to receive(:get)
          .with('redirects_path_ssim:"/handle/12345/678"', rows: 1)
          .and_return('response' => { 'docs' => [work_doc] })
      end

      it '301-redirects to the work permanent URL' do
        get :show, params: { alias_path: 'handle/12345/678' }
        expect(response).to have_http_status(:moved_permanently)
        expect(response.headers['Location']).to include("/concern/generic_works/#{work_id}")
      end
    end

    context 'with a path that resolves to a collection' do
      before do
        allow(Hyrax::SolrService)
          .to receive(:get)
          .with('redirects_path_ssim:"/special-collection-1"', rows: 1)
          .and_return('response' => { 'docs' => [collection_doc] })
      end

      it '301-redirects to the collection permanent URL' do
        get :show, params: { alias_path: 'special-collection-1' }
        expect(response).to have_http_status(:moved_permanently)
        expect(response.headers['Location']).to include("/collections/#{collection_id}")
      end
    end

    context 'with a path that has no matching redirect' do
      before do
        allow(Hyrax::SolrService)
          .to receive(:get)
          .and_return('response' => { 'docs' => [] })
      end

      it 'raises ActionController::RoutingError so Rails serves a 404' do
        expect { get :show, params: { alias_path: 'no-such-path' } }
          .to raise_error(ActionController::RoutingError)
      end
    end

    context 'when Solr raises an HTTP error' do
      let(:request_hash)  { { uri: URI('http://example/solr'), method: 'GET' } }
      let(:response_hash) { { status: 500, body: +'boom', headers: {} } }

      before do
        allow(Hyrax::SolrService)
          .to receive(:get)
          .and_raise(RSolr::Error::Http.new(request_hash, response_hash))
        allow(Hyrax.logger).to receive(:warn)
      end

      it 'logs and resolves to nil (404)' do
        expect { get :show, params: { alias_path: 'oops' } }
          .to raise_error(ActionController::RoutingError)
        expect(Hyrax.logger).to have_received(:warn).with(/Redirect lookup failed/)
      end
    end

    describe 'caching' do
      before do
        allow(Hyrax::SolrService)
          .to receive(:get)
          .and_return('response' => { 'docs' => [work_doc] })
      end

      it 'consults Solr at most once per cached path within the TTL' do
        2.times { get :show, params: { alias_path: 'cached-path' } }
        expect(Hyrax::SolrService).to have_received(:get).once
      end

      it 'consults Solr separately for distinct paths' do
        get :show, params: { alias_path: 'first-path' }
        get :show, params: { alias_path: 'second-path' }
        expect(Hyrax::SolrService).to have_received(:get).twice
      end
    end
  end
end
