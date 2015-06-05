require 'spec_helper'

describe DownloadsController do
  describe '#show' do
    let(:user) { FactoryGirl.create(:user) }
    let(:another_user) { FactoryGirl.create(:user) }
    let(:image_file_path) { Rails.root.join('../fixtures/files/image.png') }
    let(:image_file) { File.open(image_file_path) }
    let(:generic_file) {
      FactoryGirl.create(:file_with_work, user: user, content: curation_concerns_fixture_file_upload('files/image.png', 'image/png', false))
    }

    it "raise not_found if the object does not exist" do
      get :show, id: '8675309'
      expect(response).to be_not_found
    end

    context "when user doesn't have access" do
      before do
        generic_file
        sign_in another_user
      end
      it "redirects to root" do
        get :show, id: generic_file.to_param
        expect(response).to redirect_to root_path
        expect(flash["alert"]).to eq "You are not authorized to access this page."
      end
    end

    context "when user isn't logged in" do
      before { generic_file }
      it "redirects to sign in" do
        get :show, id: generic_file.to_param
        expect(response).to redirect_to new_user_session_path
        expect(flash["alert"]).to eq "You are not authorized to access this page."
      end
    end

    it 'sends the file if the user has access' do
      generic_file
      sign_in user
      get :show, id: generic_file.to_param
      expect(response.body).to eq generic_file.content.content
    end

    it 'sends requested file content' do
      Hydra::Works::AddFileToGenericFile.call(generic_file, image_file_path, :thumbnail)
      # generic_file.thumbnail.content = image_file
      # generic_file.save!
      # Hydra::Works::GenerateThumbnail.call(generic_file, content: :content)
      sign_in user
      get :show, id: generic_file.to_param, file: 'thumbnail'
      expect(response.body).to eq generic_file.thumbnail.content
    end
  end
end
