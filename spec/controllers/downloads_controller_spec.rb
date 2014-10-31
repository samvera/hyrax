require 'spec_helper'

describe DownloadsController, :type => :controller do

  describe "with a file" do
    before do
      @f = GenericFile.new(pid: 'sufia:test1')
      @f.apply_depositor_metadata('archivist1@example.com')
      @f.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      @f.save!
    end

    after do
      @f.delete
    end

    describe "when logged in as reader" do
      before do
        sign_in FactoryGirl.find_or_create(:archivist)
        allow_any_instance_of(User).to receive(:groups).and_return([])
        allow(controller).to receive(:clear_session_user) ## Don't clear out the authenticated session
      end
      describe "show" do
        it "should default to returning configured default download" do
          expect(DownloadsController.default_content_dsid).to eq("content")
          allow(controller).to receive(:render) # send_data calls render internally
          expected_content = ActiveFedora::Base.find("sufia:test1", cast: true).content.content
          expect(controller).to receive(:send_file_headers!).with({filename: 'world.png', disposition: 'inline', type: 'image/png' })
          get "show", id: "test1"
          expect(response.body).to eq(expected_content)
          expect(response).to be_success
        end
        it "should return requested datastreams" do
          allow(controller).to receive(:render) # send_data calls render internally
          expected_content = ActiveFedora::Base.find("sufia:test1", cast: true).descMetadata.content
          expect(controller).to receive(:send_file_headers!).with(filename: 'descMetadata', disposition: 'inline', type: 'application/n-triples')
          get "show", id: "test1", datastream_id: "descMetadata"
          expect(response.body).to eq(expected_content)
          expect(response).to be_success
        end
        it "should support setting disposition to inline" do
          allow(controller).to receive(:render) # send_data calls render internally
          expected_content = ActiveFedora::Base.find("sufia:test1", cast: true).content.content
          expect(controller).to receive(:send_file_headers!).with({filename: 'world.png', disposition: 'inline', type: 'image/png' })
          get "show", id: "test1", disposition: "inline"
          expect(response.body).to eq(expected_content)
          expect(response).to be_success
        end

        it "should allow you to specify filename for download" do
          allow(controller).to receive(:render) # send_data calls render internally
          expected_content = ActiveFedora::Base.find("sufia:test1", cast: true).content.content
          expect(controller).to receive(:send_file_headers!).with({filename: 'my%20dog.png', disposition: 'inline', type: 'image/png' })
          get "show", id: "test1", "filename" => "my%20dog.png"
          expect(response.body).to eq(expected_content)
        end
      end
    end

    describe "when not logged in as reader" do
      before do
        sign_in FactoryGirl.find_or_create(:jill)
        allow_any_instance_of(User).to receive(:groups).and_return([])
        allow(controller).to receive(:clear_session_user) ## Don't clear out the authenticated session
      end

      describe "show" do
        it "should deny access" do
          get "show", id: "test1"
          expect(response).to redirect_to root_path
          expect(flash[:alert]).to eq('You are not authorized to access this page.')
        end
      end
    end
  end
end
