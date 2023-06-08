# frozen_string_literal: true

RSpec.describe Hyrax::DownloadsController, valkyrie_adapter: :test_adapter, storage_adapter: :test_disk do
  routes { Hyrax::Engine.routes }

  describe '#show' do
    let(:file_path) { fixture_path + '/world.png' }
    let(:original_file) { File.open(file_path) }
    let(:user) { FactoryBot.create(:user) }

    let(:original_file_use)  { Hyrax::FileMetadata::Use::ORIGINAL_FILE }
    let(:original_file_metadata) { FactoryBot.valkyrie_create(:hyrax_file_metadata, use: original_file_use, file_identifier: "disk://#{file_path}") }
    let(:file_set) do
      if Hyrax.config.use_valkyrie?
        FactoryBot.valkyrie_create(:hyrax_file_set,
          :in_work,
          files: [original_file_metadata],
          edit_users: [user],
          visibility_setting: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
      else
        create(:file_with_work, user: user, content: original_file)
      end
    end

    it 'raises an error if the object does not exist' do
      expect do
        get :show, params: { id: '8675309' }
      end.to raise_error Blacklight::Exceptions::RecordNotFound
    end

    context "when user doesn't have access" do
      let(:another_user) { create(:user) }

      before do
        sign_in another_user
        allow(subject).to receive(:authorize!).and_return(true)
        allow(subject).to receive(:workflow_restriction?).and_return(true)
      end

      it 'returns :unauthorized status with image content' do
        get :show, params: { id: file_set.to_param }
        expect(response).to have_http_status(:unauthorized)
        expect(response.content_type).to eq 'image/png'
      end
    end

    context "when user isn't logged in" do
      context "and the unauthorized image exists" do
        before do
          allow(File).to receive(:exist?).and_return(true)
          allow(subject).to receive(:authorize!).and_return(false)
          allow(subject).to receive(:workflow_restriction?).and_return(true)
        end

        it 'returns :unauthorized status with image content' do
          get :show, params: { id: file_set.to_param }
          expect(response).to have_http_status(:unauthorized)
          expect(response.content_type).to eq 'image/png'
        end
      end
    end

    context "when the user has access" do
      let(:original_file_use)  { Hyrax::FileMetadata::Use::ORIGINAL_FILE }
      let(:thumbnail_use)      { Hyrax::FileMetadata::Use::THUMBNAIL }
      let(:file_path) { fixture_path + '/image.png' }
      let(:original_file_metadata) { FactoryBot.valkyrie_create(:hyrax_file_metadata, use: original_file_use, file_identifier: "disk://#{file_path}") }
      let(:thumbnail_file_metadata) { FactoryBot.valkyrie_create(:hyrax_file_metadata, use: thumbnail_use, file_identifier: "disk://#{file_path}") }
      let(:original_file) { File.open(file_path) }
      let(:file_set) do
        if Hyrax.config.use_valkyrie?
          FactoryBot.valkyrie_create(:hyrax_file_set,
            :in_work,
            files: [original_file_metadata, thumbnail_file_metadata],
            edit_users: [user],
            visibility_setting: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
        else
          create(:file_with_work, user: user, content: original_file)
        end
      end

      before do
        sign_in user
      end

      context 'with original file' do
        before do
          allow(subject).to receive(:authorize!).and_return(true)
          allow(subject).to receive(:workflow_restriction?).and_return(false)
        end

        it 'sends the original file' do
          get :show, params: { id: file_set }
          expect(response.body).to eq IO.binread(file_path)
        end
      end

      context 'when restricted by workflow' do
        before do
          allow(subject).to receive(:authorize!).and_return(true)
          allow(subject).to receive(:workflow_restriction?).and_return(true)
        end

        it 'returns :unauthorized status with image content' do
          get :show, params: { id: file_set.to_param }
          expect(response).to have_http_status(:unauthorized)
          expect(response.content_type).to eq 'image/png'
        end
      end

      context "with an alternative file" do
        context "that is persisted" do
          let(:original_file_use)  { Hyrax::FileMetadata::Use::ORIGINAL_FILE }
          let(:thumbnail_use)      { Hyrax::FileMetadata::Use::THUMBNAIL }
          let(:file_path) { fixture_path + '/world.png' }
          let(:original_file_metadata) do
            FactoryBot.valkyrie_create(:hyrax_file_metadata, mime_type: 'image/png', original_filename: 'world.png', use: original_file_use, file_identifier: "disk://#{file_path}")
          end
          let(:thumbnail_file_metadata) do
            FactoryBot.valkyrie_create(:hyrax_file_metadata, use: thumbnail_use, mime_type: 'image/png', original_filename: 'world.png', file_identifier: "disk://#{file_path}")
          end
          let(:original_file) { File.open(file_path) }

          let(:file_set) do
            if Hyrax.config.use_valkyrie?
              allow(subject).to receive(:authorize_download!).and_return(true)
              FactoryBot.valkyrie_create(:hyrax_file_set, :in_work, files: [original_file_metadata, thumbnail_file_metadata], edit_users: [user],
                                                                    visibility_setting: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
            else
              FactoryBot.create(:file_with_work, user: user, content: original_file)
            end
          end

          let(:file) { File.open(fixture_path + '/world.png', 'rb') }
          let(:content) { file.read }

          before do
            allow(Hyrax::DerivativePath).to receive(:derivative_path_for_reference).and_return(fixture_path + '/world.png')
          end

          it 'sends requested file content' do
            get :show, params: { id: file_set, file: 'thumbnail' }
            expect(response).to be_successful
            expect(response.body).to eq content
            expect(response.headers['Content-Length']).to eq '4218'
            expect(response.headers['Accept-Ranges']).to eq "bytes"
          end

          it 'sends 304 response when client has valid cached data' do
            get :show, params: { id: file_set, file: 'thumbnail' }
            expect(response).to have_http_status :success
            request.env['HTTP_IF_MODIFIED_SINCE'] = response.headers['Last-Modified']
            request.env['HTTP_IF_NONE_MATCH'] = response.headers['ETag']
            get :show, params: { id: file_set, file: 'thumbnail' }
            expect(response).to have_http_status :not_modified
          end

          context "stream" do
            it "head request" do
              request.env["HTTP_RANGE"] = 'bytes=0-15'
              head :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.headers['Content-Length']).to eq '16'
              expect(response.headers['Accept-Ranges']).to eq 'bytes'
              expect(response.headers['Content-Type']).to start_with 'image/png'
            end

            it "sends the whole thing" do
              request.env["HTTP_RANGE"] = 'bytes=0-4217'
              get :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.headers["Content-Range"]).to eq 'bytes 0-4217/4218'
              expect(response.headers["Content-Length"]).to eq '4218'
              expect(response.headers['Accept-Ranges']).to eq 'bytes'
              expect(response.headers['Content-Type']).to start_with "image/png"
              expect(response.headers["Content-Disposition"]).to include "inline; filename=\"world.png\""
              expect(response.body).to eq content
              expect(response.status).to eq 206
            end

            it "sends the whole thing when the range is open ended" do
              request.env["HTTP_RANGE"] = 'bytes=0-'
              get :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.body).to eq content
            end

            it "gets a range not starting at the beginning" do
              request.env["HTTP_RANGE"] = 'bytes=4200-4217'
              get :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.headers["Content-Range"]).to eq 'bytes 4200-4217/4218'
              expect(response.headers["Content-Length"]).to eq '18'
            end

            it "gets a range not ending at the end" do
              request.env["HTTP_RANGE"] = 'bytes=4-11'
              get :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.headers["Content-Range"]).to eq 'bytes 4-11/4218'
              expect(response.headers["Content-Length"]).to eq '8'
            end
          end
        end
      end
    end

    context "that isn't persisted" do
      before do
        allow(subject).to receive(:authorize!).and_return(true)
        allow(subject).to receive(:workflow_restriction?).and_return(false)
      end

      it "raises an error if the requested file does not exist" do
        expect do
          get :show, params: { id: file_set.to_param, file: 'thumbnail' }
        end.to raise_error Hyrax::ObjectNotFoundError
      end
    end

    context 'no association' do
      before do
        allow(subject).to receive(:authorize!).and_return(true)
        allow(subject).to receive(:workflow_restriction?).and_return(false)
      end

      it "raises an error if the requested association does not exist" do
        expect do
          get :show, params: { id: file_set, file: 'non-existant' }
        end.to raise_error Hyrax::ObjectNotFoundError
      end
    end
  end

  describe "derivative_download_options" do
    before do
      allow(controller).to receive(:default_file).and_return 'world.png'
    end
    subject { controller.send(:derivative_download_options) }

    it { is_expected.to eq(disposition: 'inline', type: 'image/png') }
  end
end
