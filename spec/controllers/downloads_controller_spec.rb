require 'spec_helper'

describe DownloadsController do
  describe '#show' do
    let(:user) { FactoryGirl.create(:user) }
    let(:another_user) { FactoryGirl.create(:user) }
    let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    let(:image_file) { File.open(Rails.root.join('../fixtures/files/image.png')) }
    let(:generic_file) {
      FactoryGirl.create_generic_file(:generic_work, user, worthwhile_fixture_file_upload('files/image.png', 'image/png', false)) {|g|
        g.visibility = visibility
      }
    }

    it "raise not_found if the object does not exist" do
      expect {
        get :show, id: '8675309'
      }.to raise_rescue_response_type(:not_found)
    end

    it "responds :unauthorized if user doesn't have access" do
      generic_file
      sign_in another_user
      expect {
        get :show, id: generic_file.to_param
      }.to raise_rescue_response_type(:unauthorized)
    end

    it "responds :unauthorized if you aren't logged in" do
      generic_file
      expect {
        get :show, id: generic_file.to_param
      }.to raise_rescue_response_type(:unauthorized)
    end

    it 'sends the file if the user has access' do
      generic_file
      sign_in user
      get :show, id: generic_file.to_param
      response.body.should == generic_file.content.content
    end

    it 'sends requested datastream content' do
      generic_file.datastreams['thumbnail'].content = image_file
      generic_file.save!
      sign_in user
      get :show, id: generic_file.to_param, datastream_id: 'thumbnail'
      response.body.should == generic_file.thumbnail.content
    end
  end
end
