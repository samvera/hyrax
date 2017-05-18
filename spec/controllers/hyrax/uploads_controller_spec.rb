describe Hyrax::UploadsController do
  let(:user) { create(:user) }
  describe "#create" do
    let(:file) { fixture_file_upload('/world.png', 'image/png') }

    context "when signed in" do
      before do
        sign_in user
      end
      it "is successful" do
        post :create, params: { files: [file], format: 'json' }
        expect(response).to be_success
        expect(assigns(:upload)).to be_kind_of Hyrax::UploadedFile
        expect(assigns(:upload)).to be_persisted
        expect(assigns(:upload).user).to eq user
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
