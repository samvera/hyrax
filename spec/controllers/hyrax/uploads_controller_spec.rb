# frozen_string_literal: true
RSpec.describe Hyrax::UploadsController do
  let(:user) { create(:user) }
  let(:chunk) { fixture_file_upload('/world.png', 'image/png') }

  describe "#create" do
    let(:file) { fixture_file_upload('/world.png', 'image/png') }
    let!(:existing_file) { create(:uploaded_file, file: file, user: user) }

    context "when signed in" do
      before do
        sign_in user
      end

      it "is successful" do
        post :create, params: { files: [file], format: 'json' }
        expect(response).to be_successful
        expect(assigns(:upload)).to be_kind_of Hyrax::UploadedFile
        expect(assigns(:upload)).to be_persisted
        expect(assigns(:upload).user).to eq user
      end

      context "when uploading in chunks" do
        it "appends chunks in correct sequence" do
          original_file = fixture_file_upload('/world.png', 'image/png')
          post :create, params: { files: [original_file], format: 'json' }
          original_upload = assigns(:upload)

          initial_size = original_upload.file.size
          request.headers['CONTENT-RANGE'] = "bytes #{initial_size}-#{initial_size + original_file.size - 1}/5000"
          first_chunk = fixture_file_upload('/world.png', 'image/png')
          post :create, params: { files: [first_chunk], id: original_upload.id, format: 'json' }
          original_upload.reload
          expected_size_after_first_chunk = initial_size * 2
          expect(original_upload.file.size).to eq(expected_size_after_first_chunk)

          request.headers['CONTENT-RANGE'] = "bytes #{initial_size * 2}-#{(initial_size * 2) + original_file.size - 1}/5000"
          second_chunk = fixture_file_upload('/world.png', 'image/png')
          post :create, params: { files: [second_chunk], id: original_upload.id, format: 'json' }
          original_upload.reload
          expected_size_after_second_chunk = initial_size * 3
          expect(original_upload.file.size).to eq(expected_size_after_second_chunk)
        end

        it "replaces file if chunks are mismatched" do
          original_file = fixture_file_upload('/world.png', 'image/png')
          post :create, params: { files: [original_file], format: 'json' }
          original_upload = assigns(:upload)
          original_content = File.read(original_upload.file.path)

          request.headers['CONTENT-RANGE'] = 'bytes 2000-2999/5000'
          different_chunk = fixture_file_upload('/different_file.png', 'image/png')
          post :create, params: { files: [different_chunk], id: original_upload.id, format: 'json' }

          original_upload.reload
          new_content = File.read(original_upload.file.path)
          expect(new_content).not_to eq(original_content)
        end

        it "updates the file size after replacing mismatched chunks" do
          original_file = fixture_file_upload('/world.png', 'image/png')
          post :create, params: { files: [original_file], format: 'json' }
          original_upload = assigns(:upload)
          original_size = original_upload.file.size

          request.headers['CONTENT-RANGE'] = 'bytes 2000-2999/5000'
          different_chunk = fixture_file_upload('/different_file.png', 'image/png')
          post :create, params: { files: [different_chunk], id: original_upload.id, format: 'json' }

          original_upload.reload
          new_size = original_upload.file.size
          expect(new_size).not_to eq(original_size)
        end

        it "does not append mismatched chunks" do
          original_file = fixture_file_upload('/world.png', 'image/png')
          post :create, params: { files: [original_file], format: 'json' }
          original_upload = assigns(:upload)

          request.headers['CONTENT-RANGE'] = 'bytes 0-999/5000'
          first_chunk = fixture_file_upload('/world.png', 'image/png')
          post :create, params: { files: [first_chunk], id: original_upload.id, format: 'json' }

          request.headers['CONTENT-RANGE'] = 'bytes 3000-3999/5000'
          out_of_order_chunk = fixture_file_upload('/different_file.png', 'image/png')
          post :create, params: { files: [out_of_order_chunk], id: original_upload.id, format: 'json' }

          original_upload.reload
          expect(original_upload.file.size).not_to eq(4000)
        end
      end
    end

    context "when not signed in" do
      it "is unauthorized" do
        post :create, params: { files: [file], format: 'json' }
        expect(response.status).to eq 401
      end
    end
  end

  describe "#destroy" do
    let(:file) { File.open(fixture_path + '/world.png') }
    let(:uploaded_file) { create(:uploaded_file, file: file, user: user) }

    context "when signed in" do
      before do
        sign_in user
      end

      it "destroys the uploaded file" do
        delete :destroy, params: { id: uploaded_file }
        expect(response.status).to eq 204
        expect(assigns[:upload]).to be_destroyed
        expect(File.exist?(uploaded_file.file.file.file)).to be false
      end

      context "for a file that doesn't belong to me" do
        let(:uploaded_file) { create(:uploaded_file, file: file) }

        it "doesn't destroy" do
          delete :destroy, params: { id: uploaded_file }
          expect(response.status).to eq 401
        end
      end
    end

    context "when not signed in" do
      it "is redirected to sign in" do
        delete :destroy, params: { id: uploaded_file }
        expect(response).to redirect_to main_app.new_user_session_path(locale: 'en')
      end
    end
  end
end
