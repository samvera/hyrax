# frozen_string_literal: true

RSpec.describe Hyrax::TranscriptsController do
  routes { Hyrax::Engine.routes }

  describe '#show' do
    let(:transcript) do
      FactoryBot.valkyrie_create(:hyrax_file_set, title: ['English Captions'])
    end
    let(:user) { create(:user) }
    before { sign_in user }

    context "when user doesn't have access" do
      it "returns :unauthorized status with image content" do
        get :show, params: { id: transcript.id, file_ext: "vtt" }
        expect(response).to have_http_status(:unauthorized)
        expect(response.content_type).to eq 'image/png'
      end
    end

    context "when user has access" do
      let(:user) { create(:admin) }
      let(:file_contents) { IO.binread(transcript_file) }
      let(:uploaded_file) { FactoryBot.create(:uploaded_file, file: transcript_file) }

      context 'with a vtt file' do
        let(:transcript_file) { File.open(fixture_path + '/sample.vtt') }
        let!(:vtt_file_metadata) do
          FactoryBot.valkyrie_create(:hyrax_file_metadata, :original_file, :with_file,
                                     file_set: transcript,
                                     original_filename: 'sample.vtt',
                                     mime_type: 'text/vtt',
                                     file: uploaded_file)
        end

        it 'sends the vtt file with the correct headers' do
          get :show, params: { id: transcript.id, file_ext: "vtt" }
          expect(response).to be_successful
          expect(response.body).to eq file_contents
          expect(response.headers['Content-Type']).to eq 'text/vtt; charset=utf-8'
          expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
          expect(response.headers['Content-Disposition']).to include 'inline'
        end
      end

      context 'with a different file type' do
        let(:transcript_file) { File.open(fixture_path + '/small_file.txt') }
        let!(:srt_file_metadata) do
          FactoryBot.valkyrie_create(:hyrax_file_metadata, :original_file, :with_file,
                                     original_filename: 'sample.srt',
                                     mime_type: 'text/plain',
                                     file_set: transcript,
                                     file: uploaded_file)
        end

        it 'sends the file with the correct headers' do
          get :show, params: { id: transcript.id, file_ext: "srt" }
          expect(response).to be_successful
          expect(response.body).to eq file_contents
          expect(response.headers['Content-Type']).to eq 'text/plain; charset=utf-8'
          expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
          expect(response.headers['Content-Disposition']).to include 'inline'
        end
      end
    end
  end
end
