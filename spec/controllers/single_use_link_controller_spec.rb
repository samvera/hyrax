require 'spec_helper'

describe SingleUseLinkController do
  before(:all) do
    Hydra::LDAP.connection.stubs(:get_operation_result).returns(OpenStruct.new({code:0, message:"Success"}))
    Hydra::LDAP.stubs(:does_user_exist?).returns(true)
    User.any_instance.stubs(:groups).returns([])

    GenericFile.any_instance.stubs(:terms_of_service).returns('1')
    @user = FactoryGirl.find_or_create(:user)
    @file = GenericFile.new
    @file.set_title_and_label('world.png')
    @file.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content', :mimeType => 'image/png')
    @file.apply_depositor_metadata(@user.user_key)
    @file.save
    @file2 = GenericFile.new
    @file2.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content', :mimeType => 'image/png')
    @file2.apply_depositor_metadata('mjg36')
    @file2.save
  end
  after(:all) do
    SingleUseLink.find(:all).each{ |l| l.delete}
    @user.delete
    @file.delete
    @file2.delete
  end
  before do
    controller.stubs(:clear_session_user) ## Don't clear out the authenticated session
  end
  describe "logged in user" do
    before do
      @user = FactoryGirl.find_or_create(:user)
      sign_in @user
      @now = DateTime.now
      DateTime.stubs(:now).returns(@now)
      @hash = "sha2hash"+@now.to_f.to_s 
      Digest::SHA2.expects(:new).returns(@hash)
    end
    after do
      sign_out @user
      SingleUseLink.find(:all).each{ |l| l.delete}
    end
    describe "GET 'generate_download'" do
      it "returns http success" do
        get 'generate_download', id:@file.pid
        response.should be_success
        assigns[:link].should == Rails.application.routes.url_helpers.download_single_use_link_path(@hash)
      end
    end
  
    describe "GET 'generate_show'" do
      it "returns http success" do
        get 'generate_show', id:@file.pid
        response.should be_success
        assigns[:link].should == Rails.application.routes.url_helpers.show_single_use_link_path(@hash)
      end
    end   
  end
  describe "unkown user" do
    describe "GET 'generate_download'" do
      it "returns http failure" do
        get 'generate_download', id:@file.pid
        response.should_not be_success
      end
    end
  
    describe "GET 'generate_show'" do
      it "returns http failure" do
        get 'generate_show', id:@file.pid
        response.should_not be_success
      end
    end   
  end
  describe "retrieval links" do
    before (:each) do
      @user = FactoryGirl.find_or_create(:user)
      sign_in @user
      get 'generate_download', id:@file.pid
      @dhash =  assigns[:su].downloadKey
      get 'generate_show', id:@file.pid
      @shash=  assigns[:su].downloadKey
      sign_out @user
    end    
    describe "GET 'download'" do
      it "returns http success" do
        controller.stubs(:render)
        expected_content = ActiveFedora::Base.find(@file.pid).content.content
        controller.expects(:send_data).with(expected_content, {:filename => 'world.png', :disposition => 'inline', :type => 'image/png' })
        get :download, id:@dhash 
        response.should be_success
      end
      it "returns 404 on second attempt" do
        get :download, id:@dhash 
        response.should be_success
        get :download, id:@dhash 
        response.should_not be_success
      end
      it "returns 404 on attempt to get download with show" do
        get :download, id:@shash 
        response.should_not be_success
      end
    end

    describe "GET 'show'" do
      it "returns http success" do
        get 'show', id:@shash
        response.should be_success
        assigns[:generic_file].pid.should == @file.pid
      end
      it "returns 404 on second attempt" do
        get :show, id:@shash 
        response.should be_success
        get :show, id:@shash 
        response.should_not be_success
      end
      it "returns 404 on attempt to get show with download" do
        get :show, id:@dhash 
        response.should_not be_success
      end
    end
  end
end
