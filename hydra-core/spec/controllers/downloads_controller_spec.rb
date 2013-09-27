require 'spec_helper'

describe DownloadsController do
  before do
    Rails.application.routes.draw do
      resources :downloads
    end
  end

  describe "routing" do
    it "should route" do
      assert_recognizes( {:controller=>"downloads", :action=>"show", "id"=>"test1"}, "/downloads/test1?filename=my%20dog.jpg" )
    end
  end

  describe "with a file" do
    before do
      @user = User.new.tap {|u| u.email = 'email@example.com'; u.password = 'password'; u.save}
      @obj = ActiveFedora::Base.new
      @obj = ModsAsset.new
      @obj.label = "world.png"
      @obj.add_file_datastream('fizz', :dsid=>'buzz', :mimeType => 'image/png')
      @obj.add_file_datastream('foobarfoobarfoobar', :dsid=>'content', :mimeType => 'image/png')
      @obj.add_file_datastream("It's a stream", :dsid=>'descMetadata', :mimeType => 'text/plain')
      @obj.read_users = [@user.user_key]
      @obj.save!
    end
    after do
      @obj.destroy
    end 
    describe "when logged in as reader" do
      before do
        sign_in @user
        User.any_instance.stub(:groups).and_return([])
      end
      describe "show" do
        it "should default to returning default download configured by object" do
          ModsAsset.stub(:default_content_ds).and_return('buzz')
          get "show", :id => @obj.pid
          response.should be_success
          response.headers['Content-Type'].should == "image/png"
          response.headers["Content-Disposition"].should == "inline; filename=\"world.png\""
          response.body.should == 'fizz'
        end
        it "should default to returning default download configured by controller" do
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
      describe "stream" do
        before do
          stub_response = double()
          stub_response.stub(:read_body).and_yield("one1").and_yield('two2').and_yield('thre').and_yield('four')
          stub_repo = double()
          stub_repo.stub(:datastream_dissemination).and_yield(stub_response)
          stub_ds = ActiveFedora::Datastream.new
          stub_ds.stub(:repository).and_return(stub_repo)
          stub_ds.stub(:mimeType).and_return('video/webm')
          stub_ds.stub(:dsSize).and_return(16)
          stub_ds.stub(:dsid).and_return('webm')
          stub_ds.stub(:pid).and_return('changeme:test')
          stub_file = double('stub object', datastreams: {'webm' => stub_ds}, pid:'changeme:test', label: "MyVideo.webm")
          ActiveFedora::Base.should_receive(:load_instance_from_solr).with('changeme:test').and_return(stub_file)
          controller.stub(:can?).with(:read, 'changeme:test').and_return(true)
          controller.stub(:log_download)
        end
        it "head request" do
          request.env["HTTP_RANGE"] = 'bytes=0-15'
          head :show, id: 'changeme:test', datastream_id: 'webm'
          response.headers['Content-Length'].should == 16
          response.headers['Accept-Ranges'].should == 'bytes'
          response.headers['Content-Type'].should == 'video/webm'
        end
        it "should send the whole thing" do
          request.env["HTTP_RANGE"] = 'bytes=0-15'
          get :show, id: 'changeme:test', datastream_id: 'webm'
          response.body.should == 'one1two2threfour'
          response.headers["Content-Range"].should == 'bytes 0-15/16'
          response.headers["Content-Length"].should == '16'
          response.headers['Accept-Ranges'].should == 'bytes'
          response.headers['Content-Type'].should == "video/webm"
          response.headers["Content-Disposition"].should == "inline; filename=\"MyVideo.webm\""
          response.status.should == 206
        end
        it "should send the whole thing when the range is open ended" do
          request.env["Range"] = 'bytes=0-'
          get :show, id: 'changeme:test', datastream_id: 'webm'
          response.body.should == 'one1two2threfour'
        end
        it "should get a range not starting at the beginning" do
          request.env["HTTP_RANGE"] = 'bytes=3-15'
          get :show, id: 'changeme:test', datastream_id: 'webm'
          response.body.should == '1two2threfour'
          response.headers["Content-Range"].should == 'bytes 3-15/16'
          response.headers["Content-Length"].should == '13'
        end
        it "should get a range not ending at the end" do
          request.env["HTTP_RANGE"] = 'bytes=4-11'
          get :show, id: 'changeme:test', datastream_id: 'webm'
          response.body.should == 'two2thre'
          response.headers["Content-Range"].should == 'bytes 4-11/16'
          response.headers["Content-Length"].should == '8'
        end
      end
    end

    describe "when not logged in as reader" do
      describe "show" do
        before do
          sign_in User.new.tap {|u| u.email = 'email2@example.com'; u.password = 'password'; u.save}
        end
        it "should deny access" do
          lambda { get "show", :id =>@obj.pid }.should raise_error Hydra::AccessDenied
        end
      end
    end

    describe "overriding the default asset param key" do
      before do
        Rails.application.routes.draw do
          scope 'objects/:object_id' do
            get 'download' => 'downloads#show'
          end
        end
        sign_in @user
      end
      it "should use the custom param value to retrieve the asset" do
        controller.stub(:asset_param_key).and_return(:object_id)
        get "show", :object_id => @obj.pid
        response.should be_successful
      end
    end

  end
end
