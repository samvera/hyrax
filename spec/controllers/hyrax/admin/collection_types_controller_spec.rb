RSpec.describe Hyrax::Admin::CollectionTypesController, type: :controller do
  context "anonymous user" do
    describe "#index" do
      it "returns http redirect" do
        get :index
        expect(response).to have_http_status(:redirect)
      end
    end

    describe "#create" do
      it "returns http redirect" do
        post :create
        expect(response).to have_http_status(:redirect)
      end
    end

    describe "#new" do
      it "returns http redirect" do
        get :new
        expect(response).to have_http_status(:redirect)
      end
    end

    describe "#edit" do
      it "returns http redirect" do
        get :edit, params: { id: :id }
        expect(response).to have_http_status(:redirect)
      end
    end

    describe "#update" do
      it "returns http redirect" do
        put :update, params: { id: :id }
        expect(response).to have_http_status(:redirect)
      end
    end

    describe "#destroy" do
      it "returns http redirect" do
        delete :destroy, params: { id: :id }
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  context "unauthorized user" do
    let(:user) { create(:user) }

    before do
      allow(controller.current_ability).to receive(:can?).with(any_args).and_return(false)
      sign_in user
    end

    describe "#index" do
      it "returns http redirect" do
        get :index
        expect(response).to have_http_status(:redirect)
      end
    end

    describe "#create" do
      it "returns http redirect" do
        post :create
        expect(response).to have_http_status(:redirect)
      end
    end

    describe "#new" do
      it "returns http redirect" do
        get :new
        expect(response).to have_http_status(:redirect)
      end
    end

    describe "#edit" do
      it "returns http redirect" do
        get :edit, params: { id: :id }
        expect(response).to have_http_status(:redirect)
      end
    end

    describe "#update" do
      it "returns http redirect" do
        put :update, params: { id: :id }
        expect(response).to have_http_status(:redirect)
      end
    end

    describe "#destroy" do
      it "returns http redirect" do
        delete :destroy, params: { id: :id }
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  context "authorized user" do
    let(:user) { create(:user) }

    before do
      allow(controller.current_ability).to receive(:can?).with(any_args).and_return(true)
      sign_in user
    end

    describe "#index" do
      it "returns http success" do
        get :index
        expect(response).to have_http_status(:success)
      end
    end

    describe "#create" do
      it "returns http success" do
        post :create
        expect(response).to have_http_status(:success)
      end
    end

    describe "#new" do
      it "returns http success" do
        get :new
        expect(response).to have_http_status(:success)
      end
    end

    describe "#edit" do
      it "returns http success" do
        get :edit, params: { id: :id }
        expect(response).to have_http_status(:success)
      end
    end

    describe "#update" do
      it "returns http success" do
        put :update, params: { id: :id }
        expect(response).to have_http_status(:success)
      end
    end

    describe "#destroy" do
      it "returns success" do
        delete :destroy, params: { id: :id }
        expect(response).to have_http_status(:success)
      end
    end
  end
end
