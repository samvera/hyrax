describe DownloadsController, type: :controller do
  routes { Rails.application.routes }
  describe "with a file" do
    let(:depositor) { create(:user) }
    let(:io) do
      Hydra::Derivatives::IoDecorator.new(File.open(fixture_path + '/world.png'),
                                          'image/png', 'world.png')
    end
    let(:file) do
      FileSet.new do |fs|
        fs.apply_depositor_metadata(depositor.user_key)
        fs.label = 'world.png'
        fs.save!
        Hydra::Works::UploadFileToFileSet.call(fs, io)
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
        let(:expected_datastream) { object.original_file }
        let(:expected_content) { expected_datastream.content }

        it "defaults to returning configured default download" do
          expect(described_class.default_content_path).to eq :original_file
          expect(controller).to receive(:send_file_headers!).with(filename: 'world.png', disposition: 'inline', type: 'image/png')
          get "show", id: file
          expect(response).to be_success
          expect(response.body).to eq expected_content
        end

        it "supports setting disposition to inline" do
          expect(controller).to receive(:send_file_headers!).with(filename: 'world.png', disposition: 'inline', type: 'image/png')
          get "show", id: file, disposition: "inline"
          expect(response.body).to eq expected_content
          expect(response).to be_success
        end

        it "allows you to specify filename for download" do
          expect(controller).to receive(:send_file_headers!).with(filename: 'my%20dog.png', disposition: 'inline', type: 'image/png')
          get "show", id: file, "filename" => "my%20dog.png"
          expect(response.body).to eq expected_content
          expect(response).to be_success
        end
      end
    end

    describe "when not logged in as reader" do
      before do
        sign_in create(:user)
      end

      describe "show" do
        it "denies access" do
          get "show", id: file
          expect(response).to redirect_to root_path
          expect(flash[:alert]).to eq 'You are not authorized to access this page.'
        end
      end
    end
  end
end
