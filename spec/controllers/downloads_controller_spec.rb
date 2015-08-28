require 'spec_helper'

describe DownloadsController do
  describe '#show' do
    let(:user) { FactoryGirl.create(:user) }
    let(:generic_file) do
      FactoryGirl.create(:file_with_work, user: user, content: File.open(fixture_file_path('files/image.png')))
    end
    it 'raise not_found if the object does not exist' do
      get :show, id: '8675309'
      expect(response).to be_not_found
    end

    context "when user doesn't have access" do
      let(:another_user) { FactoryGirl.create(:user) }
      before do
        sign_in another_user
      end
      it 'redirects to root' do
        get :show, id: generic_file.to_param
        expect(response).to redirect_to root_path
        expect(flash['alert']).to eq 'You are not authorized to access this page.'
      end
    end

    context "when user isn't logged in" do
      it 'redirects to sign in' do
        get :show, id: generic_file.to_param
        expect(response).to redirect_to new_user_session_path
        expect(flash['alert']).to eq 'You are not authorized to access this page.'
      end
    end

    context "when the user has access" do
      before do
        sign_in user
      end

      it 'sends the original file' do
        get :show, id: generic_file
        expect(response.body).to eq generic_file.original_file.content
      end

      context "with an alternative file" do
        context "that is persisted" do
          let(:file) { File.open(fixture_file_path('world.png'), 'rb') }

          let(:content) { file.rewind; file.read }

          before do
            CurationConcerns::PersistDerivatives.call(generic_file, file, 'thumbnail')
          end

          it 'sends requested file content' do
            get :show, id: generic_file, file: 'thumbnail'
            expect(response.body).to eq content
            expect(response.headers['Content-Length']).to eq "4218"
            expect(response.headers['Accept-Ranges']).to eq "bytes"
          end
        end

        context "that isn't persisted" do
          it "returns 404 if the requested file does not exist" do
            get :show, id: generic_file, file: 'thumbnail'
            expect(response.status).to eq 404
          end
        end
      end

      it "returns 404 if the requested association does not exist" do
        get :show, id: generic_file, file: 'non-existant'
        expect(response.status).to eq 404
      end
    end
  end
end
