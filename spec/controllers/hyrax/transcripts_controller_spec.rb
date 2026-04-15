# frozen_string_literal: true

RSpec.describe Hyrax::TranscriptsController do
  routes { Hyrax::Engine.routes }

  describe '#show' do
    let(:vtt_path) { fixture_path + '/sample.vtt' }
    let(:vtt_file) { File.open(vtt_path) }
    let(:vtt_content) { IO.binread(vtt_path) }
    let(:uploaded_file) { FactoryBot.create(:uploaded_file, file: vtt_file) }

    context 'with a vtt file' do
      let(:vtt_file_metadata) do
        FactoryBot.valkyrie_create(:hyrax_file_metadata, :with_file, :original_file,
                                   original_filename: 'sample.vtt',
                                   mime_type: 'text/vtt',
                                   file: uploaded_file)
      end

      it 'sends the vtt file with CORS headers' do
        get :show, params: { id: vtt_file_metadata.id, file_ext: "vtt" }
        expect(response).to be_successful
        expect(response.body).to eq vtt_content
        expect(response.headers['Content-Type']).to eq 'text/vtt; charset=utf-8'
        expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
        expect(response.headers['Content-Disposition']).to include 'inline'
      end
    end

    context 'with a different file type' do
      let(:text_file) { File.open(fixture_path + '/small_file.txt') }
      let(:uploaded_file) { FactoryBot.create(:uploaded_file, file: text_file) }
      let(:srt_content) { IO.binread(fixture_path + '/small_file.txt') }
      let(:srt_file_metadata) do
        FactoryBot.valkyrie_create(:hyrax_file_metadata, :with_file, :original_file,
                                   original_filename: 'sample.srt',
                                   mime_type: 'text/plain',
                                   file: uploaded_file)
      end

      it 'sends the file with the correct headers and extension' do
        get :show, params: { id: srt_file_metadata.id, file_ext: "srt" }
        expect(response).to be_successful
        expect(response.body).to eq srt_content
        expect(response.headers['Content-Type']).to eq 'text/plain; charset=utf-8'
        expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
        expect(response.headers['Content-Disposition']).to include 'inline'
      end
    end
  end
end
