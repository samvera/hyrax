require 'spec_helper'

describe DownloadsController do
  before do
    Rails.application.routes.draw do
      resources :downloads
      devise_for :users
      root to: 'catalog#index'
    end
  end

  describe "routing" do
    it "should route" do
      assert_recognizes( {:controller=>"downloads", :action=>"show", "id"=>"test1"}, "/downloads/test1?filename=my%20dog.jpg" )
    end
  end

  describe "with a file" do
    before do
      class ContentHolder < ActiveFedora::Base
        include Hydra::AccessControls::Permissions
        has_file_datastream 'thumbnail'
      end
      @user = User.new.tap {|u| u.email = 'email@example.com'; u.password = 'password'; u.save}
      @obj = ContentHolder.new
      @obj.label = "world.png"
      @obj.add_file_datastream('fizz', :dsid=>'buzz', :mimeType => 'image/png')
      @obj.add_file_datastream('foobarfoobarfoobar', :dsid=>'content', :mimeType => 'image/png')
      @obj.add_file_datastream("It's a stream", :dsid=>'descMetadata', :mimeType => 'text/plain')
      @obj.read_users = [@user.user_key]
      @obj.save!
    end
    after do
      @obj.destroy
      Object.send(:remove_const, :ContentHolder)
    end 
    context "when not logged in" do
      context "when a specific datastream is requested" do
        it "should redirect to the root path and display an error" do
          get "show", id: @obj.pid, datastream_id: "descMetadata"
          expect(response).to redirect_to new_user_session_path
          expect(flash[:alert]).to eq "You are not authorized to access this page."
        end
      end
    end
    context "when logged in, but without read access" do
      let(:user) { User.new.tap {|u| u.email = 'email2@example.com'; u.password = 'password'; u.save} }
      before do
        sign_in user
      end
      context "when a specific datastream is requested" do
        it "should redirect to the root path and display an error" do
          get "show", id: @obj.pid, datastream_id: "descMetadata"
          expect(response).to redirect_to root_path
          expect(flash[:alert]).to eq "You are not authorized to access this page."
        end
      end
    end

    context "when logged in as reader" do
      before do
        sign_in @user
        allow_any_instance_of(User).to receive(:groups).and_return([])
      end
      describe "#show" do
        it "should default to returning default download configured by object" do
          allow(ContentHolder).to receive(:default_content_ds).and_return('buzz')
          get "show", :id => @obj.pid
          expect(response).to be_success
          expect(response.headers['Content-Type']).to eq "image/png"
          expect(response.headers["Content-Disposition"]).to eq "inline; filename=\"world.png\""
          expect(response.body).to eq 'fizz'
        end
        it "should default to returning default download configured by controller" do
          expect(DownloadsController.default_content_dsid).to eq "content"
          get "show", :id => @obj.pid
          expect(response).to be_success
          expect(response.headers['Content-Type']).to eq "image/png"
          expect(response.headers["Content-Disposition"]).to eq "inline; filename=\"world.png\""
          expect(response.body).to eq 'foobarfoobarfoobar'
        end

        context "when a specific datastream is requested" do
          context "and it doesn't exist" do
            it "should return :not_found when the datastream doesn't exist" do
              get "show", :id => @obj.pid, :datastream_id => "thumbnail"
              expect(response).to be_not_found
            end
          end
          context "and it exists" do
            it "should return it" do
              get "show", :id => @obj.pid, :datastream_id => "descMetadata"
              expect(response).to be_success
              expect(response.headers['Content-Type']).to eq "text/plain"
              expect(response.headers["Content-Disposition"]).to eq "inline; filename=\"world.png\""
              expect(response.body).to eq "It's a stream"
            end
          end
        end
        it "should support setting disposition to inline" do
          get "show", :id => @obj.pid, :disposition => "inline"
          expect(response).to be_success
          expect(response.headers['Content-Type']).to eq "image/png"
          expect(response.headers["Content-Disposition"]).to eq "inline; filename=\"world.png\""
          expect(response.body).to eq 'foobarfoobarfoobar'
        end
        it "should allow you to specify filename for download" do
          get "show", :id => @obj.pid, "filename" => "my%20dog.png"
          expect(response).to be_success
          expect(response.headers['Content-Type']).to eq "image/png"
          expect(response.headers["Content-Disposition"]).to eq "inline; filename=\"my%20dog.png\""
          expect(response.body).to eq 'foobarfoobarfoobar'
        end
      end
      describe "stream" do
        before do
          stub_response = double
          allow(stub_response).to receive(:read_body).and_yield("one1").and_yield('two2').and_yield('thre').and_yield('four')
          stub_repo = double
          allow(stub_repo).to receive(:datastream_dissemination).and_yield(stub_response)
          stub_ds = ActiveFedora::Datastream.new
          allow(stub_ds).to receive(:repository).and_return(stub_repo)
          allow(stub_ds).to receive(:mimeType).and_return('video/webm')
          allow(stub_ds).to receive(:dsSize).and_return(16)
          allow(stub_ds).to receive(:dsid).and_return('webm')
          allow(stub_ds).to receive(:new?).and_return(false)
          allow(stub_ds).to receive(:pid).and_return('changeme:test')
          stub_file = double('stub object', datastreams: {'webm' => stub_ds}, pid:'changeme:test', label: "MyVideo.webm")
          expect(ActiveFedora::Base).to receive(:load_instance_from_solr).with('changeme:test').and_return(stub_file)
          allow(controller).to receive(:authorize!).with(:download, stub_ds).and_return(true)
          allow(controller).to receive(:log_download)
        end
        it "head request" do
          request.env["HTTP_RANGE"] = 'bytes=0-15'
          head :show, id: 'changeme:test', datastream_id: 'webm'
          expect(response.headers['Content-Length']).to eq 16
          expect(response.headers['Accept-Ranges']).to eq 'bytes'
          expect(response.headers['Content-Type']).to eq 'video/webm'
        end
        it "should send the whole thing" do
          request.env["HTTP_RANGE"] = 'bytes=0-15'
          get :show, id: 'changeme:test', datastream_id: 'webm'
          expect(response.body).to eq 'one1two2threfour'
          expect(response.headers["Content-Range"]).to eq 'bytes 0-15/16'
          expect(response.headers["Content-Length"]).to eq '16'
          expect(response.headers['Accept-Ranges']).to eq 'bytes'
          expect(response.headers['Content-Type']).to eq "video/webm"
          expect(response.headers["Content-Disposition"]).to eq "inline; filename=\"MyVideo.webm\""
          expect(response.status).to eq 206
        end
        it "should send the whole thing when the range is open ended" do
          request.env["Range"] = 'bytes=0-'
          get :show, id: 'changeme:test', datastream_id: 'webm'
          expect(response.body).to eq 'one1two2threfour'
        end
        it "should get a range not starting at the beginning" do
          request.env["HTTP_RANGE"] = 'bytes=3-15'
          get :show, id: 'changeme:test', datastream_id: 'webm'
          expect(response.body).to eq '1two2threfour'
          expect(response.headers["Content-Range"]).to eq 'bytes 3-15/16'
          expect(response.headers["Content-Length"]).to eq '13'
        end
        it "should get a range not ending at the end" do
          request.env["HTTP_RANGE"] = 'bytes=4-11'
          get :show, id: 'changeme:test', datastream_id: 'webm'
          expect(response.body).to eq 'two2thre'
          expect(response.headers["Content-Range"]).to eq 'bytes 4-11/16'
          expect(response.headers["Content-Length"]).to eq '8'
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
        allow(controller).to receive(:asset_param_key).and_return(:object_id)
        get "show", :object_id => @obj.pid
        expect(response).to be_successful
      end
    end

    describe "overriding the can_download? method" do
      before { sign_in @user }
      context "current_ability.can? returns true / can_download? returns false" do
        it "should authorize according to can_download?" do
          expect(controller.current_ability.can?(:download, @obj.datastreams['buzz'])).to be true
          allow(controller).to receive(:can_download?).and_return(false)
          Deprecation.silence(Hydra::Controller::DownloadBehavior) do
            get :show, id: @obj, datastream_id: 'buzz'
          end
          expect(response).to redirect_to root_url
        end
      end
      context "current_ability.can? returns false / can_download? returns true" do
        before do
          @obj.rightsMetadata.clear_permissions!
          @obj.save
        end
        it "should authorize according to can_download?" do
          expect(controller.current_ability.can?(:download, @obj.datastreams['buzz'])).to be false
          allow(controller).to receive(:can_download?).and_return(true)
          Deprecation.silence(Hydra::Controller::DownloadBehavior) do
            get :show, id: @obj, datastream_id: 'buzz'
          end
          expect(response).to be_successful
        end
      end
    end

  end
end
