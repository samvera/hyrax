require 'spec_helper'

describe DownloadsController, :type => :controller do

  describe "with a file" do
    let(:depositor) { FactoryGirl.find_or_create(:archivist) }
    let(:file) do
      GenericFile.new.tap do |f|
        f.apply_depositor_metadata(depositor.user_key)
        f.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
        f.save!
      end
    end

    before { allow_any_instance_of(User).to receive(:groups).and_return([]) }

    describe "when logged in as reader" do
      before do
        sign_in depositor
      end
      describe "show" do
        before do
          allow(controller).to receive(:render) # send_data calls render internally
        end
        let(:object) { ActiveFedora::Base.find(file.id) }
        let(:expected_datastream) { object.content }
        let(:expected_content) { expected_datastream.content }

        it "should default to returning configured default download" do
          expect(DownloadsController.default_content_dsid).to eq "content"
          expect(controller).to receive(:send_file_headers!).with({filename: 'world.png', disposition: 'inline', type: 'image/png' })
          get "show", id: file
          expect(response.body).to eq expected_content
          expect(response).to be_success
        end

        context "when grabbing a metadata datastream" do
          let(:expected_datastream) { object.descMetadata }

          it "should return requested datastreams" do
            expect(controller).to receive(:send_file_headers!).with(filename: 'descMetadata', disposition: 'inline', type: 'application/n-triples')
            get "show", id: file, datastream_id: "descMetadata"
            expect(response.body).to eq expected_content
            expect(response).to be_success
          end
        end

        it "should support setting disposition to inline" do
          expect(controller).to receive(:send_file_headers!).with({filename: 'world.png', disposition: 'inline', type: 'image/png' })
          get "show", id: file, disposition: "inline"
          expect(response.body).to eq expected_content
          expect(response).to be_success
        end

        it "should allow you to specify filename for download" do
          expect(controller).to receive(:send_file_headers!).with({filename: 'my%20dog.png', disposition: 'inline', type: 'image/png' })
          get "show", id: file, "filename" => "my%20dog.png"
          expect(response.body).to eq expected_content
          expect(response).to be_success
        end
      end
    end

    describe "when not logged in as reader" do
      before do
        sign_in FactoryGirl.find_or_create(:jill)
      end

      describe "show" do
        it "should deny access" do
          get "show", id: file
          expect(response).to redirect_to root_path
          expect(flash[:alert]).to eq 'You are not authorized to access this page.'
        end
      end
    end
  end
end
