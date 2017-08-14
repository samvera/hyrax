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
    let(:collection_type) { create(:user_collection_type) }

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

      it 'adds breadcrumbs' do
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.controls.home'), root_path)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.breadcrumbs.admin'), dashboard_path)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.admin.sidebar.configuration'), '#')
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.admin.collection_types.index.breadcrumb'), admin_collection_types_path)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.admin.collection_types.new.header'), new_admin_collection_type_path)
        get :new
        expect(response).to be_success
        expect(response).to render_template "layouts/dashboard"
      end

      it 'defines a form' do
        get :new
        expect(response).to be_success
        expect(assigns[:form]).to be_kind_of Hyrax::Forms::Admin::CollectionTypeForm
      end
    end

    describe "#edit" do
      it "returns http success" do
        get :edit, params: { id: collection_type.id }
        expect(response).to have_http_status(:success)
      end
    end

    describe "#update" do
      it "returns http success" do
        put :update, params: { id: collection_type.id }
        expect(response).to have_http_status(:success)
      end
    end

    describe "#destroy" do
      it "returns success" do
        delete :destroy, params: { id: collection_type.id }
        expect(response).to have_http_status(:success)
      end

      it 'adds breadcrumbs' do
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.controls.home'), root_path)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.breadcrumbs.admin'), dashboard_path)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.admin.sidebar.configuration'), '#')
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.admin.collection_types.index.breadcrumb'), admin_collection_types_path)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.admin.collection_types.edit.header'), edit_admin_collection_type_path(collection_type.id))
        get :edit, params: { id: collection_type.id }
        expect(response).to be_success
        expect(response).to render_template "layouts/dashboard"
      end

      it 'defines a form' do
        get :edit, params: { id: collection_type.id }
        expect(response).to be_success
        expect(assigns[:form]).to be_kind_of Hyrax::Forms::Admin::CollectionTypeForm
      end
    end
  end
end
