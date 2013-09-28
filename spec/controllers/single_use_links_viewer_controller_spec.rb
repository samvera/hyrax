require 'spec_helper'

describe SingleUseLinksViewerController do
  before(:all) do
    @user = FactoryGirl.find_or_create(:user)
    @file = GenericFile.new
    @file.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
    @file.apply_depositor_metadata(@user)
    @file.save
    @file2 = GenericFile.new
    @file2.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
    @file2.apply_depositor_metadata('mjg36')
    @file2.save
  end
  after(:all) do
    @file.delete
    @file2.delete
    SingleUseLink.delete_all
  end
  before do
    controller.stub(:has_access?).and_return(true)
    controller.stub(:clear_session_user) ## Don't clear out the authenticated session
  end
  
  describe "retrieval links" do
    let :show_link do
      SingleUseLink.create itemId: @file.pid, path: Sufia::Engine.routes.url_helpers.generic_file_path(:id => @file)
    end

    let :download_link do
      SingleUseLink.create itemId: @file.pid, path: Sufia::Engine.routes.url_helpers.download_path(:id => @file)
    end

    let :show_link_hash do
      show_link.downloadKey
    end

    let :download_link_hash do
      download_link.downloadKey
    end

    before (:each) do
      @user.delete
    end
    describe "GET 'download'" do
      it "and_return http success" do
        controller.stub(:render)
        expected_content = ActiveFedora::Base.find(@file.pid, cast: true).content.content
        controller.should_receive(:send_file_headers!).with({:filename => 'world.png', :disposition => 'inline', :type => 'image/png' })
        get :download, id:download_link_hash 
        response.body.should == expected_content
        response.should be_success
      end
      it "and_return 404 on second attempt" do
        get :download, id:download_link_hash
        response.should be_success
        get :download, id:download_link_hash
        response.should render_template('error/single_use_error') 
      end
      it "and_return 404 on attempt to get download with show" do
        get :download, id:download_link_hash
        response.should be_success
        get :show, id:download_link_hash
        response.should render_template('error/single_use_error')
      end
    end

    describe "GET 'show'" do
      it "and_return http success" do

        get 'show', id:show_link_hash
        response.should be_success
        assigns[:asset].pid.should == @file.pid
      end
      it "and_return 404 on second attempt" do
        get :show, id:show_link_hash
        response.should be_success
        get :show, id:show_link_hash
        response.should render_template('error/single_use_error')
      end
      it "and_return 404 on attempt to get show path with download hash" do
        get :show, id:download_link_hash
        response.should render_template('error/single_use_error')
      end
    end
  end

end
