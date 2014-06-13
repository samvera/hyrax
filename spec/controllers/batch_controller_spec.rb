require 'spec_helper'

describe BatchController do
  before do
    controller.stub(:has_access?).and_return(true)
    @user = FactoryGirl.find_or_create(:jill)
    sign_in @user
    User.any_instance.stub(:groups).and_return([])
    controller.stub(:clear_session_user) ## Don't clear out the authenticated session
  end
  after do
    @user.delete
  end
  describe "#update" do
    before do
      @batch = Batch.new
      @batch.save
      @file = GenericFile.new(batch: @batch)
      @file.apply_depositor_metadata(@user)
      @file.save
      @file2 = GenericFile.new(batch: @batch)
      @file2.apply_depositor_metadata('otherUser')
      @file2.save
    end
    after do
      @batch.delete
      @file.delete
      @file2.delete
    end
    it "should not be editable" do
      ability = Ability.new(@user)
      expect(ability.can?(:edit, @file)).to be true
      expect(ability.can?(:edit, @file2)).to be false
    end
    it "should enqueue a batch update job" do
      params = {'generic_file' => {'read_groups_string' => '', 'read_users_string' => 'archivist1, archivist2', 'tag' => ['']}, 'id' => @batch.pid, 'controller' => 'batch', 'action' => 'update'}
      s1 = double('one')
      BatchUpdateJob.should_receive(:new).with(@user.user_key, params).and_return(s1)
      Sufia.queue.should_receive(:push).with(s1).once
      post :update, id: @batch.pid, "generic_file" => {"read_groups_string" => "", "read_users_string" => "archivist1, archivist2", "tag" => [""]}
    end
    it "should show flash messages" do
      post :update, id: @batch.pid, "generic_file" => {"read_groups_string" => "","read_users_string" => "archivist1, archivist2", "tag" => [""]}
      response.should redirect_to @routes.url_helpers.dashboard_files_path
      flash[:notice].should_not be_nil
      flash[:notice].should_not be_empty
      flash[:notice].should include("Your files are being processed")
    end

    describe "when user has edit permissions on a file" do
      it "should set the groups" do
        post :update, id: @batch.pid, "generic_file"=>{"permissions"=>{"group"=>{"public"=>"1", "registered"=>"2"}}}
        @file.reload.read_groups.should == []
        @file.reload.edit_groups.should == []
        response.should redirect_to @routes.url_helpers.dashboard_files_path
      end

      it "should set the users with read access" do
        post :update, id: @batch.pid, "generic_file"=>{"read_groups_string"=>"", "read_users_string"=>"archivist1, archivist2", "tag"=>[""]}
        file = GenericFile.find(@file.pid)
        file.read_users.should == ['archivist1', 'archivist2']

        response.should redirect_to @routes.url_helpers.dashboard_files_path
      end
      it "should set the groups with read access" do
        post :update, id: @batch.pid, "generic_file"=>{"read_groups_string"=>"group1, group2", "read_users_string"=>"", "tag"=>[""]}
        file = GenericFile.find(@file.pid)
        file.read_groups.should == ['group1', 'group2']
      end
      it "should set public read access" do
        post :update, id: @batch.pid, "visibility"=>"open", "generic_file"=>{"read_groups_string"=>"", "read_users_string"=>"", "tag"=>[""]}
        file = GenericFile.find(@file.pid)
        file.read_groups.should == ['public']
      end
      it "should set public read access and groups at the same time" do
        post :update, id: @batch.pid, "visibility"=>"open", "generic_file"=>{"read_groups_string"=>"group1, group2", "read_users_string"=>"", "tag"=>[""]}
        file = GenericFile.find(@file.pid)
        file.read_groups.should == ['group1', 'group2', 'public']
      end
      it "should set public discover access and groups at the same time" do
        post :update, id: @batch.pid, "permission"=>{"group"=>{"public"=>"none"}}, "generic_file"=>{"read_groups_string"=>"group1, group2", "read_users_string"=>"", "tag"=>[""]}
        file = GenericFile.find(@file.pid)
        file.read_groups.should == ['group1', 'group2']
        file.discover_groups.should == []
      end
      it "should set metadata like title" do
        post :update, id: @batch.pid, "generic_file"=>{"tag"=>["footag", "bartag"]}, "title"=>{@file.pid=>"New Title"}
        file = GenericFile.find(@file.pid)
        file.title.should == ["New Title"]
        file.tag.should == ["footag", "bartag"]
      end
      it "should not set any tags" do
        post :update, id: @batch.pid, "generic_file"=>{"read_groups_string"=>"", "read_users_string"=>"archivist1", "tag"=>[""]}
        file = GenericFile.find(@file.pid)
        file.tag.should be_empty
      end
    end
    describe "when user does not have edit permissions on a file" do
      it "should not modify the object" do
        file = GenericFile.find(@file2.pid)
        file.title = "Original Title"
        file.read_groups.should == []
        file.save
        post :update, id: @batch.pid, "generic_file"=>{"read_groups_string"=>"group1, group2", "read_users_string"=>"", "tag"=>[""]}, "title"=>{@file2.pid=>"Title Wont Change"}
        file = GenericFile.find(@file2.pid)
        file.title.should == ["Original Title"]
        file.read_groups.should == []
      end
    end
  end
  describe "#edit" do
    before do
      User.any_instance.stub(:display_name).and_return("Jill Z. User")
      @b1 = Batch.new
      @b1.save
      @file = GenericFile.new(batch: @b1, label: 'f1')
      @file.apply_depositor_metadata(@user)
      @file.save
      @file2 = GenericFile.new(batch: @b1, label: 'f2')
      @file2.apply_depositor_metadata(@user)
      @file2.save
    end
    after do
      @b1.delete
      @file.delete
      @file2.delete
    end
    it "should default creator" do
      get :edit, id: @b1.id
      assigns[:generic_file].creator[0].should == @user.display_name
      assigns[:generic_file].title[0].should == 'f1'
    end
  end
end
