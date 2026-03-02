# frozen_string_literal: true

RSpec.describe Hyrax::TranscriptionsController do
  routes { Hyrax::Engine.routes }

  describe '#show' do
    let(:vtt_path) { fixture_path + '/sample.vtt' }
    let(:vtt_file) { File.open(vtt_path) }
    let(:vtt_content) { IO.binread(vtt_path) }
    let(:uploaded_file) { FactoryBot.create(:uploaded_file, file: vtt_file) }

    let(:vtt_file_metadata) do
      FactoryBot.valkyrie_create(:hyrax_file_metadata, :with_file, :original_file,
                                 original_filename: 'sample.vtt',
                                 mime_type: 'text/vtt',
                                 file: uploaded_file)
    end

    it 'sends the vtt file with CORS headers' do
      get :show, params: { id: vtt_file_metadata.id }
      expect(response).to be_successful
      expect(response.body).to eq vtt_content
      expect(response.headers['Content-Type']).to eq 'text/vtt'
      expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
      expect(response.headers['Content-Disposition']).to include 'inline'
    end
  end
end
