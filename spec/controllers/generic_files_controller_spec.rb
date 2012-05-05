require 'spec_helper'

describe GenericFilesController do
  before do
    @user = FactoryGirl.find_or_create(:user)
    sign_in @user
    controller.stubs(:clear_session_user) ## Don't clear out the authenticated session
  end
  describe "#create" do
    before do
      @file_count = GenericFile.count
      @mock = GenericFile.new({:pid => 'test:123'})
      GenericFile.expects(:new).returns(@mock)
    end
    after do
      begin
        Batch.find("sample:batch_id").delete
      rescue
      end
      @mock.delete
    end

    it "should expand zip files" do
      file = fixture_file_upload('/world.png','application/zip')
      Delayed::Job.expects(:enqueue).with {|job| job.kind_of? CharacterizeJob}
      Delayed::Job.expects(:enqueue).with {|job| job.kind_of? UnzipJob}
      xhr :post, :create, :files=>[file], :Filename=>"The world", :batch_id => "sample:batch_id", :permission=>{"group"=>{"public"=>"discover"} }
    end
    
    it "should create and save a file asset from the given params" do
      file = fixture_file_upload('/world.png','image/png')
      xhr :post, :create, :files=>[file], :Filename=>"The world", :batch_id => "sample:batch_id", :permission=>{"group"=>{"public"=>"discover"} }
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
      file = fixture_file_upload('/world.png','image/png')
      controller.stubs(:add_posted_blob_to_asset)
      xhr :post, :create, :files=>[file], :Filename=>"The world", :batch_id => "sample:batch_id", :permission=>{"group"=>{"public"=>"discover"} }
      lambda {Batch.find("sample:batch_id")}.should raise_error(ActiveFedora::ObjectNotFoundError) # The controller shouldn't actually save the Batch
      b = Batch.create(pid: "sample:batch_id")
      b.generic_files.first.pid.should == "test:123"
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
    
    it "should add a new groups and users" do
      post :update, :id=>@generic_file.pid, :generic_file=>{:permissions=>{:new_group_name=>'group1', :new_group_permission=>'discover', :new_user_name=>'user1', :new_user_permission=>'edit'}}

      assigns[:generic_file].discover_groups.should == ["group1"]
      assigns[:generic_file].edit_users.should include("user1", @user.login)
    end
    it "should update existing groups and users" do
      @generic_file.read_groups = ['group3']
      @generic_file.save
      post :update, :id=>@generic_file.pid, :generic_file=>{:permissions=>{:new_group_name=>'', :new_group_permission=>'', :new_user_name=>'', :new_user_permission=>'', :group=>{'group3' =>'read'}}}

      assigns[:generic_file].read_groups.should == ["group3"]
    end

  end

end
