# frozen_string_literal: true

RSpec.describe Hyrax::IiifAvController, type: :controller do
  routes { Hyrax::Engine.routes }

  let(:file_set_id) { '12345' }
  let(:solr_document) { {} }
  let(:presenter) do
    instance_double("Hyrax::FileSetPresenter", solr_document: solr_document)
  end

  before do
    allow(controller).to receive(:presenter).and_return(nil)
  end

  describe '#content' do
    context 'with head request' do
      it 'returns unauthorized (401) with invalid auth token' do
        allow(controller).to receive(:can?).and_return(false)
        request.headers['Authorization'] = "Bearer bad-token"
        expect(head(:content, params: { id: file_set_id, label: 'mp4' })).to have_http_status(:unauthorized)
      end

      context 'with valid token' do
        let(:token) do
          allow(controller).to receive(:can?).and_return(true)
          get(:auth_token, params: { id: file_set_id, messageId: 1, origin: "https://example.com" })
          response.body.match(/accessToken\":\"(.+)\"}/)[1]
        end

        it 'returns ok (200)' do
          allow(controller).to receive(:can?).and_return(false)
          request.headers['Authorization'] = "Bearer #{token}"
          expect(head(:content, params: { id: file_set_id, label: 'mp4' })).to have_http_status(:ok)
        end
      end

      context 'with public content' do
        it 'returns ok (200)' do
          allow(controller).to receive(:can?).and_return(true)
          expect(head(:content, params: { id: file_set_id, label: 'mp4' })).to have_http_status(:ok)
        end
      end
    end

    it 'returns unauthorized (401) if cannot read the preservation file' do
      expect(get(:content, params: { id: file_set_id, label: 'mp4' })).to have_http_status(:unauthorized)
    end

    context 'with video file' do
      it 'redirects to the content' do
        allow(controller).to receive(:presenter).and_return(presenter)
        expect(get(:content, params: { id: file_set_id, label: 'mp4' })).to have_http_status(302)
        expect(response).to redirect_to Hyrax::Engine.routes.url_helpers.download_path(file_set_id, file: 'mp4', locale: nil)
      end
    end

    context 'when the file is an audio derivative with metadata' do
      let(:solr_document) { { 'derivatives_metadata_ssi' => derivatives_metadata.to_json } }
      let(:derivatives_metadata) do
        [
          { id: '1', label: 'high', file_location_uri: 'http://streaming.server/streams/high.mp3' },
          { id: '2', label: 'medium', file_location_uri: 'http://streaming.server/streams/medium.mp3' }
        ]
      end

      before do
        allow(controller).to receive(:presenter).and_return(presenter)
      end

      around do |example|
        current_builder = Hyrax.config.iiif_av_url_builder
        Hyrax.config.iiif_av_url_builder = ->(file_location_uri, _base_url) { file_location_uri }
        example.run
        Hyrax.config.iiif_av_url_builder = current_builder
      end

      it 'redirects to the content' do
        expect(get(:content, params: { id: file_set_id, label: 'high' })).to have_http_status(302)
        expect(response).to redirect_to 'http://streaming.server/streams/high.mp3'
      end

      context 'with custom av url builder' do
        let(:custom_builder) do
          ->(file_location_uri, _base_url) { "http://different.host.example.com/stream/#{File.basename(file_location_uri)}" }
        end

        around do |example|
          current_builder = Hyrax.config.iiif_av_url_builder
          Hyrax.config.iiif_av_url_builder = custom_builder
          example.run
          Hyrax.config.iiif_av_url_builder = current_builder
        end

        it 'redirects to the content' do
          expect(get(:content, params: { id: file_set_id, label: 'high' })).to have_http_status(302)
          expect(response).to redirect_to 'http://different.host.example.com/stream/high.mp3'
        end
      end
    end
  end

  describe '#auth_token' do
    it 'returns unauthorized (401) if cannot read the preservation file' do
      allow(controller).to receive(:can?).and_return(false)
      expect(get(:auth_token, params: { id: file_set_id, messageId: 1, origin: "https://example.com" })).to have_http_status(:unauthorized)
    end

    it 'returns the postMessage with auth token' do
      allow(controller).to receive(:can?).and_return(true)
      get(:auth_token, params: { id: file_set_id, messageId: 1, origin: "https://example.com" })
      expect(response).to have_http_status(:ok)
      expect(response.body.gsub(/\s+/, '')).to match(/window.parent.postMessage\({"messageId":"1","accessToken":".+"},"https:\/\/example.com"\);/)
    end
  end

  describe '#sign_in' do
    it 'returns a page that closes' do
      sign_in create(:user)
      get(:sign_in)
      expect(response).to have_http_status(:ok)
      expect(response.body.gsub(/\s+/, '')).to match(/\<script\>window.close\(\)\;\<\/script\>/)
    end
  end
end
