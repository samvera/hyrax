require 'spec_helper'

describe GenericFilesController do
  before do
    GenericFile.any_instance.stubs(:terms_of_service).returns('1')
    @user = FactoryGirl.find_or_create(:user)
    sign_in @user
    User.any_instance.stubs(:groups).returns([])
    controller.stubs(:clear_session_user) ## Don't clear out the authenticated session
  end
  describe "#create" do
    before do
      GenericFile.any_instance.stubs(:terms_of_service).returns('1')
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
      xhr :post, :create, :files=>[file], :Filename=>"The world", :batch_id => "sample:batch_id", :permission=>{"group"=>{"public"=>"read"} }, :terms_of_service=>"1"
    end

    it "should create and save a file asset from the given params" do
      file = fixture_file_upload('/world.png','image/png')
      xhr :post, :create, :files=>[file], :Filename=>"The world", :batch_id => "sample:batch_id", :permission=>{"group"=>{"public"=>"read"} }, :terms_of_service=>"1"
      response.should be_success
      GenericFile.count.should == @file_count + 1

      saved_file = GenericFile.find('test:123')

      # This is confirming that the correct file was attached
      saved_file.label.should == 'world.png'
      saved_file.content.checksum.should == 'f794b23c0c6fe1083d0ca8b58261a078cd968967'
      saved_file.content.dsChecksumValid.should be_true

      # Confirming that date_uploaded and date_modified were set
      saved_file.date_uploaded.should have_at_least(1).items
      saved_file.date_modified.should have_at_least(1).items
    end

    it "should record what user created the first version of content" do
      file = fixture_file_upload('/world.png','image/png')
      xhr :post, :create, :files=>[file], :Filename=>"The world", :terms_of_service=>"1"

      saved_file = GenericFile.find('test:123')
      version = saved_file.content.latest_version
      version.versionID.should == "content.0"
      saved_file.content.version_committer(version).should == @user.login
    end

    it "should create batch associations from batch_id" do
      Rails.application.config.stubs(:id_namespace).returns('sample')
      file = fixture_file_upload('/world.png','image/png')
      controller.stubs(:add_posted_blob_to_asset)
      xhr :post, :create, :files=>[file], :Filename=>"The world", :batch_id => "sample:batch_id", :permission=>{"group"=>{"public"=>"read"} }, :terms_of_service=>"1"
      lambda {Batch.find("sample:batch_id")}.should raise_error(ActiveFedora::ObjectNotFoundError) # The controller shouldn't actually save the Batch
      b = Batch.create(pid: "sample:batch_id")
      b.generic_files.first.pid.should == "test:123"
    end
    it "should set the depositor id" do
      file = fixture_file_upload('/world.png','image/png')
      xhr :post, :create, :files => [file], :Filename => "The world", :batch_id => "sample:batch_id", :permission => {"group"=>{"public"=>"read"} }, :terms_of_service => "1"
      response.should be_success

      saved_file = GenericFile.find('test:123')
      # This is confirming that apply_depositor_metadata recorded the depositor
      saved_file.properties.depositor.should == ['jilluser']
      saved_file.depositor.should == 'jilluser'
      saved_file.properties.to_solr.keys.should include('depositor_t')
      saved_file.properties.to_solr['depositor_t'].should == ['jilluser']
      saved_file.to_solr.keys.should include('depositor_t')
      saved_file.to_solr['depositor_t'].should == ['jilluser']
    end
  end

  describe "audit" do
    before do
      @cur_delay = Delayed::Worker.delay_jobs
      @generic_file = GenericFile.new
      @generic_file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content')
      @generic_file.apply_depositor_metadata('mjg36')
      @generic_file.save
    end
    after do
      @generic_file.delete
      Delayed::Worker.delay_jobs = @cur_delay #return to original delay state
    end
    it "should return json with the result" do
      Delayed::Worker.delay_jobs = false
      xhr :post, :audit, :id=>@generic_file.pid
      response.should be_success
      lambda { JSON.parse(response.body) }.should_not raise_error
      audit_results = JSON.parse(response.body).collect { |result| result["checksum_audit_log"]["pass"] }
      audit_results.reduce(true) { |sum, value| sum && value }.should be_true
    end
  end

  describe "update" do
    before do
      GenericFile.any_instance.stubs(:terms_of_service).returns('1')
      @generic_file = GenericFile.new
      @generic_file.apply_depositor_metadata(@user.login)
      @generic_file.save
    end
    after do
      @generic_file.delete
    end

    it "should record what user added a new version" do
      @user = FactoryGirl.find_or_create(:user)
      sign_in @user

      file = fixture_file_upload('/world.png','image/png')
      post :update, :id=>@generic_file.pid, :filedata=>file, :Filename=>"The world", :generic_file=>{:terms_of_service=>"1", :permissions=>{:new_user_name=>{'archivist1'=>'edit'}}}

      posted_file = GenericFile.find(@generic_file.pid)
      version1 = posted_file.content.latest_version
      posted_file.content.version_committer(version1).should == @user.login

      # other user uploads new version
      archivist = FactoryGirl.find_or_create(:archivist)
      controller.stubs(:current_user).returns(archivist)
      sign_in archivist

      file = fixture_file_upload('/image.jp2','image/jp2')
      post :update, :id=>@generic_file.pid, :filedata=>file, :Filename=>"The world", :generic_file=>{:terms_of_service=>"1"}

      edited_file = GenericFile.find(@generic_file.pid)
      version2 = edited_file.content.latest_version
      version2.versionID.should_not == version1.versionID
      edited_file.content.version_committer(version2).should == archivist.login

      # original user restores his or her version
      controller.stubs(:current_user).returns(@user)
      sign_in @user
      post :update, :id=>@generic_file.pid, :revision=>'content.0', :generic_file=>{:terms_of_service=>"1"}

      restored_file = GenericFile.find(@generic_file.pid)
      version3 = restored_file.content.latest_version
      version3.versionID.should_not == version2.versionID
      version3.versionID.should_not == version1.versionID
      restored_file.content.version_committer(version3).should == @user.login
    end

    it "should add a new groups and users" do
      post :update, :id=>@generic_file.pid, :generic_file=>{:terms_of_service=>"1", :permissions=>{:new_group_name=>{'group1'=>'read'}, :new_user_name=>{'user1'=>'edit'}}}

      assigns[:generic_file].read_groups.should == ["group1"]
      assigns[:generic_file].edit_users.should include("user1", @user.login)
    end
    it "should update existing groups and users" do
      @generic_file.read_groups = ['group3']
      @generic_file.save
      post :update, :id=>@generic_file.pid, :generic_file=>{:terms_of_service=>"1", :permissions=>{:new_group_name=>'', :new_group_permission=>'', :new_user_name=>'', :new_user_permission=>'', :group=>{'group3' =>'read'}}}

      assigns[:generic_file].read_groups.should == ["group3"]
    end
  end

  describe "someone elses files" do
    before(:all) do
      GenericFile.any_instance.stubs(:terms_of_service).returns('1')
      f = GenericFile.new(:pid => 'scholarsphere:test5')
      f.apply_depositor_metadata('archivist1')
      f.set_title_and_label('world.png')
      f.add_file_datastream(File.new(Rails.root +  'spec/fixtures/world.png'))
      # grant public read access explicitly
      f.update_attributes({:read_groups_string => 'public'})
      f.expects(:characterize_if_changed).yields
      f.save
    end
    after(:all) do
      GenericFile.find('scholarsphere:test5').delete
    end
    describe "edit" do
      it "should give me a flash error" do
        get :edit, id:"test5"
        response.should redirect_to(:action => 'show')
        flash[:alert].should_not be_nil
        flash[:alert].should_not be_empty
        flash[:alert].should include("You do not have sufficient privileges to edit this document")
      end
    end
    describe "view" do
      it "should show me the file" do
        get :show, id:"test5"
        response.should_not redirect_to(:action => 'show')
        flash[:alert].should be_nil
      end
    end
  end
end
