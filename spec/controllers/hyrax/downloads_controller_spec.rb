# frozen_string_literal: true

RSpec.describe Hyrax::DownloadsController do
  routes { Hyrax::Engine.routes }

  describe '#show' do
    let(:file_path) { fixture_path + '/image.png' }
    let(:original_file) { File.open(file_path) }
    let(:original_content) { IO.binread(file_path) }
    let(:uploaded_file) { FactoryBot.create(:uploaded_file, file: original_file) }
    let(:user) { FactoryBot.create(:user) }

    let(:original_file_metadata) do
      FactoryBot.valkyrie_create(:hyrax_file_metadata, :with_file, :original_file, :image,
                                 original_filename: 'image.png',
                                 file_set: file_set,
                                 file: uploaded_file)
    end

    let(:file_set) do
      FactoryBot.valkyrie_create(:hyrax_file_set,
                                 edit_users: [user],
                                 visibility_setting: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
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
      before do
        sign_in user
      end

      context 'with original file' do
        before do
          original_file_metadata
          allow(subject).to receive(:authorize!).and_return(true)
          allow(subject).to receive(:workflow_restriction?).and_return(false)
        end

        it 'sends the original file and sends 304 response when client has valid cached data' do
          head :show, params: { id: file_set }
          head_headers = response.headers
          get :show, params: { id: file_set }
          expect(response).to have_http_status :success
          expect(response.headers['Content-Length']).to eq '19102'
          expect(response.headers['Accept-Ranges']).to eq "bytes"
          expect(response.headers).to eq head_headers
          expect(response.body).to eq IO.binread(file_path)

          # Caching
          request.env['HTTP_IF_MODIFIED_SINCE'] = response.headers['Last-Modified']
          request.env['HTTP_IF_NONE_MATCH'] = response.headers['ETag']
          get :show, params: { id: file_set }
          expect(response).to have_http_status :not_modified
        end

        context "stream" do
          it "head request" do
            request.env["HTTP_RANGE"] = 'bytes=0-15'
            head :show, params: { id: file_set }
            expect(response.headers['Content-Length']).to eq '16'
            expect(response.headers['Accept-Ranges']).to eq 'bytes'
            expect(response.headers['Content-Type']).to start_with 'image/png'
            expect(response.body).to be_blank
          end

          it "sends the whole thing" do
            request.env["HTTP_RANGE"] = 'bytes=0-19101'
            get :show, params: { id: file_set }
            expect(response.headers["Content-Range"]).to eq 'bytes 0-19101/19102'
            expect(response.headers["Content-Length"]).to eq '19102'
            expect(response.headers['Accept-Ranges']).to eq 'bytes'
            expect(response.headers['Content-Type']).to start_with "image/png"
            expect(response.headers["Content-Disposition"]).to include "attachment; filename=\"image.png\""
            expect(response.body).to eq original_content
            expect(response.status).to eq 206
          end

          it "sends the whole thing when the range is open ended" do
            request.env["HTTP_RANGE"] = 'bytes=0-'
            get :show, params: { id: file_set }
            expect(response.body).to eq original_content
          end

          it "gets a range not starting at the beginning" do
            request.env["HTTP_RANGE"] = 'bytes=19000-19101'
            get :show, params: { id: file_set }
            expect(response.headers["Content-Range"]).to eq 'bytes 19000-19101/19102'
            expect(response.headers["Content-Length"]).to eq '102'
          end

          it "gets a range not ending at the end" do
            request.env["HTTP_RANGE"] = 'bytes=4-11'
            get :show, params: { id: file_set }
            expect(response.headers["Content-Range"]).to eq 'bytes 4-11/19102'
            expect(response.headers["Content-Length"]).to eq '8'
          end
        end
      end

      # service file is only supported in valkyrie mode
      context 'with video file', skip: !Hyrax.config.use_valkyrie? do
        let(:service_file_path) { fixture_path + '/sample_mpeg4.mp4' }
        let(:service_file) { File.open(service_file_path) }
        let(:service_content) { IO.binread(service_file_path) }
        let(:service_uploaded_file) { FactoryBot.create(:uploaded_file, file: service_file) }
        let(:service_file_metadata) do
          FactoryBot.valkyrie_create(:hyrax_file_metadata, :with_file, :service_file, :video_file,
                                     original_filename: 'sample_mpeg4.mp4',
                                     file_set: file_set,
                                     file: service_uploaded_file)
        end

        before do
          original_file_metadata
          service_file_metadata
          allow(subject).to receive(:authorize!).and_return(true)
          allow(subject).to receive(:workflow_restriction?).and_return(false)
        end

        it 'accepts a mime_type param' do
          get :show, params: { id: file_set.id, file: "mp4", mime_type: 'video/mp4' }
          expect(response.body).to eq service_content
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
          let(:thumb_file_path) { fixture_path + '/world.png' }
          let(:thumb_file) { File.open(thumb_file_path) }
          let(:thumb_content) { IO.binread(thumb_file_path) }
          let(:thumb_uploaded_file) { FactoryBot.create(:uploaded_file, file: thumb_file) }
          let(:thumbnail_file_metadata) do
            FactoryBot.valkyrie_create(:hyrax_file_metadata, :with_file, :thumbnail, :image,
                                       original_filename: 'world.png',
                                       file_set: file_set,
                                       file: thumb_uploaded_file)
          end

          before do
            original_file_metadata
            thumbnail_file_metadata
            allow(subject).to receive(:authorize_download!).and_return(true)
            allow(Hyrax::DerivativePath).to receive(:derivative_path_for_reference).and_return(fixture_path + '/world.png')
          end

          it 'sends requested file content and sends 304 response when client has valid cached data' do
            head :show, params: { id: file_set, file: 'thumbnail' }
            head_headers = response.headers
            get :show, params: { id: file_set, file: 'thumbnail' }
            expect(response).to be_successful
            expect(response.body).to eq thumb_content
            expect(response.headers['Content-Length']).to eq '4218'
            expect(response.headers['Accept-Ranges']).to eq "bytes"
            expect(response.headers).to eq head_headers

            # Caching
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
              expect(response.body).to be_blank
            end

            it "sends the whole thing" do
              request.env["HTTP_RANGE"] = 'bytes=0-4217'
              get :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.headers["Content-Range"]).to eq 'bytes 0-4217/4218'
              expect(response.headers["Content-Length"]).to eq '4218'
              expect(response.headers['Accept-Ranges']).to eq 'bytes'
              expect(response.headers['Content-Type']).to start_with "image/png"
              expect(response.headers["Content-Disposition"]).to include "inline; filename=\"world.png\""
              expect(response.body).to eq thumb_content
              expect(response.status).to eq 206
            end

            it "sends the whole thing when the range is open ended" do
              request.env["HTTP_RANGE"] = 'bytes=0-'
              get :show, params: { id: file_set, file: 'thumbnail' }
              expect(response.body).to eq thumb_content
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
