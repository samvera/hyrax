require 'spec_helper'

describe DownloadsController do

  describe "with a file" do
    before do
      @f = GenericFile.new(:pid => 'sufia:test1')
      @f.apply_depositor_metadata('archivist1@example.com')
      @f.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      @f.should_receive(:characterize_if_changed).and_yield
      @f.save!
    end

    after do
      @f.delete
    end

    describe "when logged in as reader" do
      before do
        sign_in FactoryGirl.find_or_create(:archivist)
        User.any_instance.stub(:groups).and_return([])
        controller.stub(:clear_session_user) ## Don't clear out the authenticated session
      end
      after do
        arch = FactoryGirl.find(:archivist) rescue
        arch.delete if arch
      end
      describe "show" do
        it "should default to returning configured default download" do
          DownloadsController.default_content_dsid.should == "content"
          controller.stub(:render) # send_data calls render internally
          expected_content = ActiveFedora::Base.find("sufia:test1", cast: true).content.content
          controller.should_receive(:send_file_headers!).with({:filename => 'world.png', :disposition => 'inline', :type => 'image/png' })
          get "show", :id => "test1"
          response.body.should == expected_content
          response.should be_success
        end
        it "should return requested datastreams" do
          controller.stub(:render) # send_data calls render internally
          expected_content = ActiveFedora::Base.find("sufia:test1", cast: true).descMetadata.content
          controller.should_receive(:send_file_headers!).with({:filename => 'descMetadata', :disposition => 'inline', :type => 'text/plain' })
          get "show", :id => "test1", :datastream_id => "descMetadata"
          response.body.should == expected_content
          response.should be_success
        end
        it "should support setting disposition to inline" do
          controller.stub(:render) # send_data calls render internally
          expected_content = ActiveFedora::Base.find("sufia:test1", cast: true).content.content
          controller.should_receive(:send_file_headers!).with({:filename => 'world.png', :disposition => 'inline', :type => 'image/png' })
          get "show", :id => "test1", :disposition => "inline"
          response.body.should == expected_content
          response.should be_success
        end

        it "should allow you to specify filename for download" do
          controller.stub(:render) # send_data calls render internally
          expected_content = ActiveFedora::Base.find("sufia:test1", cast: true).content.content
          controller.should_receive(:send_file_headers!).with({:filename => 'my%20dog.png', :disposition => 'inline', :type => 'image/png' })
          get "show", :id => "test1", "filename" => "my%20dog.png"
          response.body.should == expected_content
        end
      end
    end

    describe "when not logged in as reader" do
      before do
        sign_in FactoryGirl.find_or_create(:user)
        User.any_instance.stub(:groups).and_return([])
        controller.stub(:clear_session_user) ## Don't clear out the authenticated session
      end
      after do
        user = FactoryGirl.find(:user) rescue
        user.delete if user
      end
      
      describe "show" do
        it "should deny access" do
          get "show", :id => "test1"
          response.should redirect_to root_path
          flash[:alert].should == "You do not have sufficient access privileges to read this document, which has been marked private."
        end
      end
    end
  end
end
