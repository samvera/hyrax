require 'spec_helper'

describe Hydra::Controller::DownloadController do

  before(:all) do
    class DownloadsController < ApplicationController
      include Hydra::Controller::DownloadController
    end
    Rails.application.routes.draw do
      resources :downloads
    end
    @controller = DownloadsController.new
  end

  after(:all) do
    @f.destroy
    Object.send(:remove_const, :DownloadsController)
  end

  describe "routing" do
    it "should route" do
      assert_recognizes( {:controller=>"downloads", :action=>"show", "id"=>"test1"}, "/downloads/test1?filename=my%20dog.jpg" )
    end
  end

  describe "with a file" do
    before (:all) do
      @user = User.create!(email: 'email@example.com', password: 'password')
      @obj = ActiveFedora::Base.new
      @obj = ModsAsset.new
      @obj.label = "world.png"
      @obj.add_file_datastream('foobarfoobarfoobar', :dsid=>'content', :mimeType => 'image/png')
      @obj.add_file_datastream("It's a stream", :dsid=>'descMetadata', :mimeType => 'text/plain')
      @obj.read_users = [@user.user_key]
      @obj.save!
    end
    describe "when logged in as reader" do
      before do
        sign_in @user
        User.any_instance.stub(:groups).and_return([])
      end
      describe "show" do
        it "should default to returning configured default download" do
          DownloadsController.default_content_dsid.should == "content"
          get "show", :id => @obj.pid
          response.should be_success
          response.headers['Content-Type'].should == "image/png"
          response.headers["Content-Disposition"].should == "inline; filename=\"world.png\""
          response.body.should == 'foobarfoobarfoobar'
        end
        it "should return requested datastreams" do
          get "show", :id => @obj.pid, :datastream_id => "descMetadata"
          response.should be_success
          response.headers['Content-Type'].should == "text/plain"
          response.headers["Content-Disposition"].should == "inline; filename=\"world.png\""
          response.body.should == "It's a stream"
        end
        it "should support setting disposition to inline" do
          get "show", :id => @obj.pid, :disposition => "inline"
          response.should be_success
          response.headers['Content-Type'].should == "image/png"
          response.headers["Content-Disposition"].should == "inline; filename=\"world.png\""
          response.body.should == 'foobarfoobarfoobar'
        end
        it "should allow you to specify filename for download" do
          get "show", :id => @obj.pid, "filename" => "my%20dog.png"
          response.should be_success
          response.headers['Content-Type'].should == "image/png"
          response.headers["Content-Disposition"].should == "inline; filename=\"my%20dog.png\""
          response.body.should == 'foobarfoobarfoobar'
        end
      end
    end

    describe "when not logged in as reader" do
      describe "show" do
        it "should deny access" do
          lambda { get "show", :id =>@obj.pid }.should raise_error Hydra::AccessDenied
        end
      end
    end
  end
end
