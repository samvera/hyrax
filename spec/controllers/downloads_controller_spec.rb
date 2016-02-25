require 'spec_helper'

describe DownloadsController do
  describe '#show' do
    let(:user) { FactoryGirl.create(:user) }
    let(:file_set) do
      FactoryGirl.create(:file_with_work, user: user, content: File.open(fixture_file_path('files/image.png')))
    end
    it 'calls render_404 if the object does not exist' do
      expect(controller).to receive(:render_404) { controller.render nothing: true }
      get :show, id: '8675309'
    end

    context "when user doesn't have access" do
      let(:another_user) { FactoryGirl.create(:user) }
      before do
        sign_in another_user
      end
      it 'redirects to root' do
        get :show, id: file_set.to_param
        expect(response).to redirect_to root_path
        expect(flash['alert']).to eq 'You are not authorized to access this page.'
      end
    end

    context "when user isn't logged in" do
      it 'redirects to sign in' do
        get :show, id: file_set.to_param
        expect(response).to redirect_to new_user_session_path
        expect(flash['alert']).to eq 'You are not authorized to access this page.'
      end
    end

    context "when the user has access" do
      before do
        sign_in user
      end

      it 'sends the original file' do
        get :show, id: file_set
        expect(response.body).to eq file_set.original_file.content
      end

      context "with an alternative file" do
        context "that is persisted" do
          let(:file) { File.open(fixture_file_path('world.png'), 'rb') }

          let(:content) { file.read }

          before do
            allow(CurationConcerns::DerivativePath).to receive(:derivative_path_for_reference).and_return(fixture_file_path('world.png'))
          end

          it 'sends requested file content' do
            get :show, id: file_set, file: 'thumbnail'
            expect(response.body).to eq content
            expect(response.headers['Content-Length']).to eq "4218"
            expect(response.headers['Accept-Ranges']).to eq "bytes"
          end
        end

        context "that isn't persisted" do
          it "returns 404 if the requested file does not exist" do
            expect(controller).to receive(:render_404) { controller.render nothing: true }
            get :show, id: file_set, file: 'thumbnail'
          end
        end
      end

      it "returns 404 if the requested association does not exist" do
        expect(controller).to receive(:render_404) { controller.render nothing: true }
        get :show, id: file_set, file: 'non-existant'
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
