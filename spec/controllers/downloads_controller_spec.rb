require 'spec_helper'

describe DownloadsController do
  
  describe "routing" do
    it "should route" do
      assert_recognizes( {:controller=>"downloads", :action=>"show", "id"=>"scholarsphere:test1"}, "/downloads/scholarsphere:test1?filename=my%20dog.jpg" )
    end
  end
  
  describe "when logged in as reader" do
    before do
      sign_in FactoryGirl.create(:archivist)
      controller.stubs(:clear_session_user) ## Don't clear out the authenticated session
    end
    describe "show" do
      it "should default to returning configured default download" do
        DownloadsController.default_content_dsid.should == "content"
        controller.stubs(:render)
        expected_content = ActiveFedora::Base.find("scholarsphere:test1").content.content
        controller.expects(:send_data).with(expected_content, {:filename => 'Test Data 1.txt', :type => 'text/plain'})
        get "show", :id=>"scholarsphere:test1"   
        response.should be_success         
      end
      it "should return requested datastreams" do
        controller.stubs(:render)
        expected_content = ActiveFedora::Base.find("scholarsphere:test1").descMetadata.content
        controller.expects(:send_data).with(expected_content, {:filename => 'descMetadata',:type=>"text/plain"})
        get "show", :id=>"scholarsphere:test1", :datastream_id=>"descMetadata"
        response.should be_success 
      end
      it "should support setting disposition to inline" do
        controller.stubs(:render)
        expected_content = ActiveFedora::Base.find("scholarsphere:test1").content.content
        controller.expects(:send_data).with(expected_content, {:filename => 'Test Data 1.txt', :type => 'text/plain', :disposition=>"inline"})
        get "show", :id=>"scholarsphere:test1", :disposition=>"inline"
        response.should be_success
      end
      it "should allow you to specify filename for download" do
        controller.stubs(:render)
        expected_content = ActiveFedora::Base.find("scholarsphere:test1").content.content
        controller.expects(:send_data).with(expected_content, {:filename=>"my%20dog.txt", :type => 'text/plain'}) 
        get "show", :id=>"scholarsphere:test1", "filename"=>"my%20dog.txt"
      end
    end
  end
  
  describe "when not logged in as reader" do
    before do
      sign_in FactoryGirl.create(:user)
      controller.stubs(:clear_session_user) ## Don't clear out the authenticated session
    end
    describe "show" do
      it "should deny access" do
        get "show", :id=>"scholarsphere:test1"
        response.should redirect_to(catalog_path)        
      end
    end
  end
  
end