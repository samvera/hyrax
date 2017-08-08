RSpec.describe Hyrax::Admin::CollectionTypesController do
  routes { Hyrax::Engine.routes }
  let(:user) { create(:user) }

  context "a non admin" do
    describe "#index" do
      it 'is unauthorized' do
        get :index
        expect(response).to be_redirect
      end
    end

    describe "#new" do
      it 'is unauthorized' do
        get :new
        expect(response).to be_redirect
      end
    end

    describe "#edit" do
      it 'is unauthorized' do
        get :edit, params: { id: 1 }
        expect(response).to be_redirect
      end
    end
  end

  context "as an admin" do
    before do
      sign_in user
      allow(controller).to receive(:authorize!).and_return(true)
    end

    describe "#index" do
      it 'allows an authorized user' do
        get :index
        expect(response).to be_success
      end
    end

    describe "#new" do
      it 'allows an authorized user' do
        get :new
        expect(response).to be_success
      end
    end

    describe "#edit" do
      it 'allows an authorized user' do
        get :edit, params: { id: 1 }
        expect(response).to be_success
      end
    end
  end
end
