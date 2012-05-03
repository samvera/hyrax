require 'spec_helper'

describe GenericFilesController do
  before do
    @user = FactoryGirl.find_or_create(:user)
    sign_in @user
    controller.stubs(:clear_session_user) ## Don't clear out the authenticated session
  end
  describe "#upload" do
    before do
      @file_count = GenericFile.count
      @mock = GenericFile.new({:pid => 'test:123'})
      GenericFile.expects(:new).returns(@mock)
      @batch = Batch.create
    end
    after do
      @mock.delete
      @batch.delete
    end
    
    it "should create and save a file asset from the given params" do
      file = fixture_file_upload('/world.png','image/png')
      xhr :post, :create, :files=>[file], :Filename=>"The world", :batch_id => @batch.pid, :permission=>{"group"=>{"public"=>"discover"} }
      response.should be_success
      GenericFile.count.should == @file_count + 1 
      
      saved_file = GenericFile.find('test:123')
      
      # This is confirming that the correct file was attached
      saved_file.label.should == 'world.png'
      saved_file.content.checksum.should == '28da6259ae5707c68708192a40b3e85c'
      saved_file.content.dsChecksumValid.should be_true
      
      # Confirming that date_uploaded and date_modified were set
      saved_file.date_uploaded.should have_at_least(1).items
      saved_file.date_modified.should have_at_least(1).items
    end
    
    it "should create batch associations from batch_id" do
      file = mock("file")
      controller.stubs(:add_posted_blob_to_asset)
      xhr :post, :create, :files=>[file], :Filename=>"The world", :batch_id => "sample:batch_id", :permission=>{"group"=>{"public"=>"discover"} }
      assigns[:batch].new_object?.should be_true # The controller shouldn't actually save the Batch
      assigns[:batch].save # saving for the sake of this test
      reloaded_batch = Batch.find(assigns[:batch].pid)
      reloaded_batch.generic_files.first.pid.should == "test:123"
    end

    
  end

  describe "audit" do
    before do
      @generic_file = GenericFile.new
      @generic_file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
      @generic_file.save
    end
    after do
      @generic_file.delete
    end
    it "should return json with the result" do
      xhr :post, :audit, :id=>@generic_file.pid
      response.should be_success
      lambda { JSON.parse(response.body) }.should_not raise_error
      audit_results = JSON.parse(response.body).collect { |result| result["checksum_audit_log"]["pass"] }
      audit_results.reduce(true) { |sum, value| sum && value }.should be_true
    end
  end

  describe "update" do
    before do
      @generic_file = GenericFile.new
      @generic_file.apply_depositor_metadata(@user.login)
      @generic_file.save
    end
    after do
      @generic_file.delete
    end
    
    it "should allow setting umgs as groups with read access" do
      post :update, :id=>@generic_file.pid, :generic_file=>{:read_groups_string=>'umg/up.dlt.gamma-ci,umg/up.dlt.redmine'}
      assigns[:generic_file].read_groups.should == ["umg/up.dlt.gamma-ci", "umg/up.dlt.redmine"]
    end
    it "should allow setting users with read access" do
      post :update, :id=>@generic_file.pid, :generic_file=>{:read_users_string=>'updlt1,updlt2 updlt3'}
      assigns[:generic_file].read_users.should == ['updlt1', 'updlt2', 'updlt3']
    end
  end

end
