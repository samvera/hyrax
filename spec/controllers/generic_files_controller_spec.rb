require 'spec_helper'

describe GenericFilesController do

  describe "audit" do
    before do
      @user = User.create(:login => "testuser", 
                          :email => "testuser@example.com", 
                          :password => "password",
                          :password_confirmation => "password")
      sign_in @user
      @generic_file = GenericFile.new
      @generic_file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
      @generic_file.save
    end
    after do
      @user.delete
      @generic_file.delete
    end
    it "should return json with the result" do
      xhr :post, :audit, :id=>@generic_file.pid
      response.should be_success
      JSON.parse(response.body)["checksum_audit_log"]["pass"].should be_true
    end
  end

end
