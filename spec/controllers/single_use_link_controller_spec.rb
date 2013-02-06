require 'spec_helper'

describe SingleUseLinkController do
  before do
    @user = FactoryGirl.find_or_create(:user)
    @file = GenericFile.new
    @file.set_title_and_label('world.png')
    @file.add_file_datastream(File.new(fixture_path + '/world.png'), :dsid=>'content', :mimeType => 'image/png')
    @file.apply_depositor_metadata(@user.user_key)
    @file.stub(:characterize_if_changed).and_yield #don't run characterization
    @file.save
    @file2 = GenericFile.new
    @file2.add_file_datastream(File.new(fixture_path + '/world.png'), :dsid=>'content', :mimeType => 'image/png')
    @file2.apply_depositor_metadata('mjg36')
    @file2.stub(:characterize_if_changed).and_yield #don't run characterization
    @file2.save
  end
  after do
    @file.delete
    @file2.delete
  end
  before do
    controller.stub(:has_access?).and_return(true)
  end
  describe "logged in user" do
    before do
      @user = FactoryGirl.find_or_create(:user)
      sign_in @user
      @now = DateTime.now
      DateTime.stub(:now).and_return(@now)
      @hash = "sha2hash"+@now.to_f.to_s 
      Digest::SHA2.should_receive(:new).and_return(@hash)
    end
    describe "GET 'generate_download'" do
      it "and_return http success" do
        get 'generate_download', id:@file.pid
        response.should be_success
        assigns[:link].should == @routes.url_helpers.download_single_use_link_path(@hash)
      end
    end
  
    describe "GET 'generate_show'" do
      it "and_return http success" do
        get 'generate_show', id:@file.pid
        response.should be_success
        assigns[:link].should == @routes.url_helpers.show_single_use_link_path(@hash)
      end
    end   
  end
  describe "unkown user" do
    describe "GET 'generate_download'" do
      it "and_return http failure" do
        get 'generate_download', id:@file.pid
        response.should_not be_success
      end
    end
  
    describe "GET 'generate_show'" do
      it "and_return http failure" do
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
      it "and_return http success" do
        controller.stub(:render)
        expected_content = ActiveFedora::Base.find(@file.pid).content.content
        controller.should_receive(:send_data).with(expected_content, {:filename => 'world.png', :disposition => 'inline', :type => 'image/png' })
        get :download, id:@dhash 
        response.should be_success
      end
      it "and_return 404 on second attempt" do
        get :download, id:@dhash 
        response.should be_success
        lambda {get :download, id:@dhash}.should raise_error ActionController::RoutingError
      end
      it "and_return 404 on attempt to get download with show" do
        lambda {get :download, id:@shash}.should raise_error ActionController::RoutingError
      end
    end

    describe "GET 'show'" do
      it "and_return http success" do
        get 'show', id:@shash
        response.should be_success
        assigns[:generic_file].pid.should == @file.pid
      end
      it "and_return 404 on second attempt" do
        get :show, id:@shash 
        response.should be_success
        lambda {get :show, id:@shash}.should raise_error ActionController::RoutingError
      end
      it "and_return 404 on attempt to get show with download" do
        lambda {get :show, id:@dhash}.should raise_error ActionController::RoutingError
      end
    end
  end
end
