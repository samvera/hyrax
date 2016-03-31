require 'spec_helper'

describe Sufia::UploadsController do
  describe "#create" do
    let(:file) { fixture_file_upload('/world.png', 'image/png') }
    let(:user) { create(:user) }

    context "when signed in" do
      before do
        sign_in user
      end
      it "is successful" do
        post :create, files: [file], format: 'json'
        expect(response).to be_success
        expect(assigns(:uploaded_file)).to be_kind_of UploadedFile
        expect(assigns(:uploaded_file)).to be_persisted
        expect(assigns(:uploaded_file).user).to eq user
      end
    end

    context "when not signed in" do
      it "is successful" do
        post :create, files: [file], format: 'json'
        expect(response.status).to eq 401
      end
    end
  end
end
