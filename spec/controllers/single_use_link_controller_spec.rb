require 'spec_helper'

describe SingleUseLinkController do
  before(:all) do
    @user = FactoryGirl.find_or_create(:user)
    @file = GenericFile.new
    @file.set_title_and_label('world.png')
    @file.add_file_datastream(File.new(fixture_path + '/world.png'), :dsid=>'content', :mimeType => 'image/png')
    @file.apply_depositor_metadata(@user.user_key)
    @file.save
    @file2 = GenericFile.new
    @file2.add_file_datastream(File.new(fixture_path + '/world.png'), :dsid=>'content', :mimeType => 'image/png')
    @file2.apply_depositor_metadata('mjg36')
    @file2.save
  end
  after(:all) do
    SingleUseLink.delete_all
    @user.delete
    @file.delete
    @file2.delete
  end
  before do
    controller.stub(:has_access?).and_return(true)
    controller.stub(:clear_session_user) ## Don't clear out the authenticated session
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
    after do
      sign_out @user
      SingleUseLink.find(:all).each{ |l| l.delete}
      @user.delete
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
      @dhash = SingleUseLink.create_download(@file.pid).downloadKey
      @shash = SingleUseLink.create_show(@file.pid).downloadKey
    end    
    before (:each) do
      @user.delete
    end
    describe "GET 'download'" do
      it "and_return http success" do
        controller.stub(:render)
        expected_content = ActiveFedora::Base.find(@file.pid).content.content
        controller.should_receive(:send_file_headers!).with({:filename => 'world.png', :disposition => 'inline', :type => 'image/png' })
        get :download, id:@dhash 
        response.body.should == expected_content
        response.should be_success
      end
      it "and_return 404 on second attempt" do
        get :download, id:@dhash 
        response.should be_success
        get :download, id:@dhash
        response.should render_template('error/single_use_error') 
      end
      it "and_return 404 on attempt to get download with show" do
        get :download, id:@dhash
        response.should be_success
        get :download, id:@dhash
        response.should render_template('error/single_use_error')
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
        get :show, id:@shash
        response.should render_template('error/single_use_error')
      end
      it "and_return 404 on attempt to get show path with download hash" do
        get :show, id:@dhash
        response.should render_template('error/single_use_error')
      end
    end
  end
end
