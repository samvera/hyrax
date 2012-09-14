require 'spec_helper'

describe DownloadsController do

  before(:all) do
    GenericFile.any_instance.stubs(:terms_of_service).returns('1')
    f = GenericFile.new(:pid => 'scholarsphere:test1')
    f.apply_depositor_metadata('archivist1')
    f.set_title_and_label('world.png')
    f.add_file_datastream(File.new(Rails.root + 'spec/fixtures/world.png'), :dsid=>'content', :mimeType => 'image/png')
    f.expects(:characterize_if_changed).yields
    f.save
  end

  after(:all) do
    GenericFile.find('scholarsphere:test1').delete
  end

  describe "routing" do
    it "should route" do
      assert_recognizes( {:controller=>"downloads", :action=>"show", "id"=>"test1"}, "/downloads/test1?filename=my%20dog.jpg" )
    end
  end

  describe "when logged in as reader" do
    before do
      sign_in FactoryGirl.find_or_create(:archivist)
      User.any_instance.stubs(:groups).returns([])
      controller.stubs(:clear_session_user) ## Don't clear out the authenticated session
    end
    describe "show" do
      it "should default to returning configured default download" do
        DownloadsController.default_content_dsid.should == "content"
        controller.stubs(:render)
        expected_content = ActiveFedora::Base.find("scholarsphere:test1").content.content
        controller.expects(:send_data).with(expected_content, {:filename => 'world.png', :disposition => 'inline', :type => 'image/png' })
        get "show", :id => "test1"
        response.should be_success
      end
      it "should return requested datastreams" do
        controller.stubs(:render)
        expected_content = ActiveFedora::Base.find("scholarsphere:test1").descMetadata.content
        controller.expects(:send_data).with(expected_content, {:filename => 'descMetadata', :disposition => 'inline', :type => "text/plain"})
        get "show", :id => "test1", :datastream_id => "descMetadata"
        response.should be_success
      end
      it "should support setting disposition to inline" do
        controller.stubs(:render)
        expected_content = ActiveFedora::Base.find("scholarsphere:test1").content.content
        controller.expects(:send_data).with(expected_content, {:filename => 'world.png', :type => 'image/png', :disposition => "inline"})
        get "show", :id => "test1", :disposition => "inline"
        response.should be_success
      end
      it "should allow you to specify filename for download" do
        controller.stubs(:render)
        expected_content = ActiveFedora::Base.find("scholarsphere:test1").content.content
        controller.expects(:send_data).with(expected_content, {:filename => "my%20dog.png", :disposition => 'inline', :type => 'image/png'}) 
        get "show", :id => "test1", "filename" => "my%20dog.png"
      end
    end
  end

  describe "when not logged in as reader" do
    before do
      sign_in FactoryGirl.find_or_create(:user)
      User.any_instance.stubs(:groups).returns([])
      controller.stubs(:clear_session_user) ## Don't clear out the authenticated session
    end
    describe "show" do
      it "should deny access" do
        get "show", :id => "test1"
        response.should redirect_to("/assets/NoAccess.png")
      end
    end
  end
end
