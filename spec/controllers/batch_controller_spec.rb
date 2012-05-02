require 'spec_helper'

describe BatchController do
  before do
    @user = FactoryGirl.find_or_create(:user)
    sign_in @user
    controller.stubs(:clear_session_user) ## Don't clear out the authenticated session
  end

  describe "#update" do
    before do
      @batch = Batch.new
      @batch.apply_depositor_metadata(@user.login)
      @batch.save
      @file = GenericFile.create(:batch=>@batch)
    end

#"permission"=>{"group"=>{"public"=>"none"}}
    it "should set the users with read access" do
      post :update, :id=>@batch.pid, "generic_file"=>{"read_groups_string"=>"", "read_users_string"=>"archivist1, archivist2", "tag"=>[""]} 
      file = GenericFile.find(@file.pid)
      file.read_users.should == ['archivist1', 'archivist2']

      response.should redirect_to dashboard_path

    end
    it "should set the groups with read access" do
      post :update, :id=>@batch.pid, "generic_file"=>{"read_groups_string"=>"group1, group2", "read_users_string"=>"", "tag"=>[""]} 
      file = GenericFile.find(@file.pid)
      file.read_groups.should == ['group1', 'group2']
    end

    it "should not set any tags" do
      post :update, :id=>@batch.pid, "generic_file"=>{"read_groups_string"=>"", "read_users_string"=>"archivist1", "tag"=>[""]} 
      file = GenericFile.find(@file.pid)
      file.tag.should be_empty
    end
  end

end

