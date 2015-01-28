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
        include Hydra::ModelMethods
        include Hydra::AccessControls::Permissions
        contains 'thumbnail'
      end
      @user = User.new.tap {|u| u.email = 'email@example.com'; u.password = 'password'; u.save}
    end
    let(:obj) do
      ContentHolder.new.tap do |obj|
        obj.add_file('fizz', 'buzz', 'buzz.png', 'image/png')
        obj.add_file('foobarfoobarfoobar', 'content', 'world.png', 'image/png')
        obj.add_file("It's a stream", 'descMetadata', 'metadata.xml', 'text/plain')
        obj.read_users = [@user.user_key]
        obj.save!
      end
    end

    after do
      obj.destroy
      Object.send(:remove_const, :ContentHolder)
    end

    context "when not logged in" do
      context "when a specific datastream is requested" do
        it "should redirect to the root path and display an error" do
          get :show, id: obj, file: "descMetadata"
          expect(response).to redirect_to new_user_session_path
          expect(flash[:alert]).to eq "You are not authorized to access this page."
        end
      end
    end
    context "when logged in, but without read access" do
      let(:user) { User.create(email: 'email2@example.com', password: 'password') }
      before do
        sign_in user
      end
      context "when a specific datastream is requested" do
        it "should redirect to the root path and display an error" do
          get :show, id: obj, file: "descMetadata"
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
          expect(Deprecation).to receive(:warn)
          get :show, id: obj
          expect(response).to be_successful
          expect(response.headers['Content-Type']).to eq "image/png"
          expect(response.headers["Content-Disposition"]).to eq "inline; filename=\"buzz.png\""
          expect(response.body).to eq 'fizz'
        end

        it "should default to returning default download configured by object" do
          allow(ContentHolder).to receive(:default_file_path).and_return('buzz')
          get :show, id: obj
          expect(response).to be_successful
          expect(response.headers['Content-Type']).to eq "image/png"
          expect(response.headers["Content-Disposition"]).to eq "inline; filename=\"buzz.png\""
          expect(response.body).to eq 'fizz'
        end

        it "should default to returning default download configured by controller" do
          expect(DownloadsController.default_file_path).to eq "content"
          get :show, id: obj
          expect(response).to be_successful
          expect(response.headers['Content-Type']).to eq "image/png"
          expect(response.headers["Content-Disposition"]).to eq "inline; filename=\"world.png\""
          expect(response.body).to eq 'foobarfoobarfoobar'
        end

        context "when a specific datastream is requested" do
          context "and it doesn't exist" do
            it "should return :not_found when the datastream doesn't exist" do
              get :show, id: obj, file: "thumbnail"
              expect(response).to be_not_found
            end
          end
          context "and it exists" do
            it "should return it" do
              get :show, id: obj, file: "descMetadata"
              expect(response).to be_successful
              expect(response.headers['Content-Type']).to eq "text/plain"
              expect(response.headers["Content-Disposition"]).to eq "inline; filename=\"metadata.xml\""
              expect(response.body).to eq "It's a stream"
            end
          end
        end
        it "should support setting disposition to inline" do
          get :show, id: obj, :disposition => "inline"
          expect(response).to be_successful
          expect(response.headers['Content-Type']).to eq "image/png"
          expect(response.headers["Content-Disposition"]).to eq "inline; filename=\"world.png\""
          expect(response.body).to eq 'foobarfoobarfoobar'
        end
        it "should allow you to specify filename for download" do
          get :show, id: obj, "filename" => "my%20dog.png"
          expect(response).to be_successful
          expect(response.headers['Content-Type']).to eq "image/png"
          expect(response.headers["Content-Disposition"]).to eq "inline; filename=\"my%20dog.png\""
          expect(response.body).to eq 'foobarfoobarfoobar'
        end
      end
      describe "stream" do
        let(:parent) { ActiveFedora::Base.new(id: '1234') }

        before do
          parent.add_file('one1two2threfour', path: 'webm', mime_type: 'video/webm', original_name: 'MyVideo.webm')
          parent.save!
          expect(controller).to receive(:authorize!).with(:download, instance_of(ActiveFedora::File)).and_return(true)
        end
        it "head request" do
          request.env["HTTP_RANGE"] = 'bytes=0-15'
          head :show, id: parent, file: 'webm'
          # See https://github.com/rails/rails/issues/18714
          # expect(response.headers['Content-Length']).to eq 16
          expect(response.headers['Accept-Ranges']).to eq 'bytes'
          expect(response.headers['Content-Type']).to eq 'video/webm'
        end
        it "should send the whole thing" do
          request.env["HTTP_RANGE"] = 'bytes=0-15'
          get :show, id: '1234', file: 'webm'
          expect(response.body).to eq 'one1two2threfour'
          expect(response.headers["Content-Range"]).to eq 'bytes 0-15/16'
          # See https://github.com/rails/rails/issues/18714
          # expect(response.headers["Content-Length"]).to eq '16'
          expect(response.headers['Accept-Ranges']).to eq 'bytes'
          expect(response.headers['Content-Type']).to eq "video/webm"
          expect(response.headers["Content-Disposition"]).to eq "inline; filename=\"MyVideo.webm\""
          expect(response.status).to eq 206
        end
        it "should send the whole thing when the range is open ended" do
          request.env["HTTP_RANGE"] = 'bytes=0-'
          get :show, id: '1234', file: 'webm'
          expect(response.body).to eq 'one1two2threfour'
        end
        it "should get a range not starting at the beginning" do
          request.env["HTTP_RANGE"] = 'bytes=3-15'
          get :show, id: '1234', file: 'webm'
          expect(response.body).to eq '1two2threfour'
          expect(response.headers["Content-Range"]).to eq 'bytes 3-15/16'
          # See https://github.com/rails/rails/issues/18714
          # expect(response.headers["Content-Length"]).to eq '13'
        end
        it "should get a range not ending at the end" do
          request.env["HTTP_RANGE"] = 'bytes=4-11'
          get :show, id: '1234', file: 'webm'
          expect(response.body).to eq 'two2thre'
          expect(response.headers["Content-Range"]).to eq 'bytes 4-11/16'
          # See https://github.com/rails/rails/issues/18714
          # expect(response.headers["Content-Length"]).to eq '8'
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
        get :show, object_id: obj
        expect(response).to be_successful
      end
    end
  end
end
