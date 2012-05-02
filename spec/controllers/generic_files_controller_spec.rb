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
      #xhr :post, :create, :Filedata=>[file], :Filename=>"The world", :permission=>{"group"=>{"public"=>"discover"}}
      #response.should redirect_to(dashboard_path)

      xhr :post, :create, :files=>[file], :Filename=>"The world", :batch_id => @batch.pid, :permission=>{"group"=>{"public"=>"discover"} }
      response.should be_success
      GenericFile.count.should == @file_count + 1 
      saved_file = GenericFile.find('test:123')
      saved_file.label.should == 'world.png'
      saved_file.content.checksum.should == '28da6259ae5707c68708192a40b3e85c'
      saved_file.content.dsChecksumValid.should be_true
      saved_file.date_uploaded.should have_at_least(1).items
      saved_file.date_modified.should have_at_least(1).items
      saved_file = GenericFile.find('test:123')
      saved_file.format_label[0].should == ''
      Delayed::Worker.new.work_off
      saved_file = GenericFile.find('test:123')
      saved_file.format_label[0].should == 'Portable Network Graphics'
      saved_file.mime_type[0].should == 'image/png'
      
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

  describe "new" do
    it "should create a batch with access controls" do
      get :new
      assigns[:batch].edit_users.should == [@user.login]
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
