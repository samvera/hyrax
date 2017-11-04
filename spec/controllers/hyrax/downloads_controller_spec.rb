RSpec.describe Hyrax::DownloadsController do
  routes { Hyrax::Engine.routes }

  describe '#show' do
    let(:user) { create(:user) }
    let(:file) { fixture_file_upload('image.png', 'image/png') }
    let(:file_set) do
      create_for_repository(:file_set, user: user, content: file)
    end
    let(:default_image) { ActionController::Base.helpers.image_path 'default.png' }

    it 'raises an error if the object does not exist' do
      expect do
        get :show, params: { id: '8675309' }
      end.to raise_error Blacklight::Exceptions::InvalidSolrID
    end

    context "when user doesn't have access" do
      let(:another_user) { create(:user) }

      before { sign_in another_user }

      it 'redirects to the default image' do
        get :show, params: { id: file_set.to_param }
        expect(response).to redirect_to default_image
      end
    end

    context "when user isn't logged in" do
      it 'redirects to the default image' do
        get :show, params: { id: file_set.to_param }
        expect(response).to redirect_to default_image
      end

      it 'authorizes the resource using only the id' do
        expect(controller).to receive(:authorize!).with(:download, file_set.id.to_s)
        get :show, params: { id: file_set.to_param }
      end
    end

    context "when the user has access" do
      before { sign_in user }

      it 'sends the original file' do
        get :show, params: { id: file_set.to_param }
        expect(response.body).to eq file.tempfile.read
      end

      context "with an alternative file" do
        context "that is persisted" do
          let(:file) { fixture_file_upload('world.png', 'image/png') }
          let(:content) { File.open(fixture_path + '/world.png', 'rb').read }

          before do
            allow(Hyrax::DerivativePath).to receive(:derivative_path_for_reference).and_return(fixture_path + '/world.png')
          end

          it 'sends requested file content' do
            get :show, params: { id: file_set.to_param, file: 'thumbnail' }
            expect(response).to be_success
            expect(response.body).to eq content
            expect(response.headers['Content-Length']).to eq "4218"
            expect(response.headers['Accept-Ranges']).to eq "bytes"
          end

          it 'retrieves the thumbnail without contacting Fedora' do
            expect(ActiveFedora::Base).not_to receive(:find).with(file_set.id)
            get :show, params: { id: file_set.to_param, file: 'thumbnail' }
          end
        end

        context "that isn't persisted" do
          it "raises an error if the requested file does not exist" do
            expect do
              get :show, params: { id: file_set.to_param, file: 'thumbnail' }
            end.to raise_error Hyrax::ObjectNotFoundError
          end
        end
      end

      it "raises an error if the requested association does not exist" do
        expect do
          get :show, params: { id: file_set.to_param, file: 'non-existant' }
        end.to raise_error Hyrax::ObjectNotFoundError
      end
    end
  end

  describe "derivative_download_options" do
    before do
      allow(controller).to receive(:default_file).and_return 'world.png'
    end
    subject { controller.send(:derivative_download_options) }

    it { is_expected.to eq(disposition: 'inline', type: 'image/png') }
  end
end
