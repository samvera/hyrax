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
    let(:valid_attributes) do
      {
        title: 'Collection type title',
        description: 'Description of collection type',
        machine_id: 'collection_type_title',
        nestable: true,
        discoverable: true,
        sharable: true,
        allow_multiple_membership: true,
        require_membership: true,
        assigns_workflow: true,
        assigns_visibility: true
      }
    end

    let(:valid_session) { {} }
    let(:collection_type) { create(:collection_type) }
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

      it 'adds breadcrumbs' do
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.controls.home'), root_path)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.breadcrumbs.admin'), dashboard_path)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.admin.sidebar.configuration'), '#')
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.admin.collection_types.index.breadcrumb'), admin_collection_types_path)
        get :index
        expect(response).to be_success
        expect(response).to render_template "layouts/dashboard"
      end
    end

    describe "#create" do
      context "with valid params" do
        it "creates a new CollectionType" do
          expect do
            post :create, params: { collection_type: valid_attributes }, session: valid_session
          end.to change(Hyrax::CollectionType, :count).by(1)
        end

        it "redirects to the created collection_type" do
          post :create, params: { collection_type: valid_attributes }, session: valid_session
          expect(response).to redirect_to(edit_admin_collection_type_path(Hyrax::CollectionType.last))
        end

        it "assigns all attributes" do
          post :create, params: { collection_type: valid_attributes }, session: valid_session
          expect(assigns[:collection_type].attributes.symbolize_keys).to include(valid_attributes)
        end
      end

      context "with invalid params" do
        it "returns a success response (i.e. to display the 'new' template)" do
          post :create, params: { collection_type: { title: collection_type.title } }, session: valid_session
          expect(response).to be_success
        end

        it 'adds breadcrumbs' do
          expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.controls.home'), root_path)
          expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.breadcrumbs.admin'), dashboard_path)
          expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.admin.sidebar.configuration'), '#')
          expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.admin.collection_types.index.breadcrumb'), admin_collection_types_path)
          expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.admin.collection_types.new.header'), new_admin_collection_type_path)
          post :create, params: { collection_type: { title: collection_type.title } }, session: valid_session
          expect(response).to be_success
          expect(response).to render_template "layouts/dashboard"
        end

        it 'defines a form' do
          post :create, params: { collection_type: { title: collection_type.title } }, session: valid_session
          expect(response).to be_success
          expect(assigns[:form]).to be_kind_of Hyrax::Forms::Admin::CollectionTypeForm
        end
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
        get :edit, params: { id: collection_type.to_param }
        expect(response).to have_http_status(:success)
      end

      it 'adds breadcrumbs' do
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.controls.home'), root_path)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.breadcrumbs.admin'), dashboard_path)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.admin.sidebar.configuration'), '#')
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.admin.collection_types.index.breadcrumb'), admin_collection_types_path)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.admin.collection_types.edit.header'), edit_admin_collection_type_path(1))
        get :edit, params: { id: collection_type.to_param }
        expect(response).to be_success
        expect(response).to render_template "layouts/dashboard"
      end

      it 'defines a form' do
        get :edit, params: { id: collection_type.to_param }
        expect(response).to be_success
        expect(assigns[:form]).to be_kind_of Hyrax::Forms::Admin::CollectionTypeForm
      end
    end

    describe "#update" do
      let(:new_attributes) do
        {
          title: 'Improved title',
          machine_id: 'improved-title',
          nestable: false,
          discoverable: false,
          sharable: false,
          allow_multiple_membership: false,
          require_membership: true,
          assigns_workflow: true,
          assigns_visibility: true
        }
      end

      context "with valid params" do
        it 'updates a record' do
          put :update, params: { id: collection_type.to_param, collection_type: new_attributes }, session: valid_session
          collection_type.reload
          expect(assigns[:collection_type].attributes.symbolize_keys).to include(new_attributes)
        end

        it "redirects to the collection_type" do
          put :update, params: { id: collection_type.to_param, collection_type: valid_attributes }, session: valid_session
          expect(response).to redirect_to(edit_admin_collection_type_path(collection_type))
        end
      end

      context "with invalid params" do
        let(:existing_collection_type) { create(:collection_type, title: 'Existing', machine_id: 'existing') }
        let(:invalid_attributes) { { title: existing_collection_type.title } }

        it "returns a success response (i.e. to display the 'edit' template)" do
          put :update, params: { id: collection_type.to_param, collection_type: invalid_attributes }, session: valid_session
          expect(response).to have_http_status(:success)
        end

        it 'adds breadcrumbs' do
          expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.controls.home'), root_path)
          expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.breadcrumbs.admin'), dashboard_path)
          expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.admin.sidebar.configuration'), '#')
          expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.admin.collection_types.index.breadcrumb'), admin_collection_types_path)
          expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.admin.collection_types.edit.header'), edit_admin_collection_type_path(1))
          put :update, params: { id: collection_type.to_param, collection_type: invalid_attributes }, session: valid_session
          expect(response).to be_success
          expect(response).to render_template "layouts/dashboard"
        end

        it 'defines a form' do
          put :update, params: { id: collection_type.to_param, collection_type: invalid_attributes }, session: valid_session
          expect(response).to be_success
          expect(assigns[:form]).to be_kind_of Hyrax::Forms::Admin::CollectionTypeForm
        end
      end
    end

    describe "#destroy" do
      it "destroys the requested collection_type" do
        expect(collection_type).to be_persisted
        expect do
          delete :destroy, params: { id: collection_type.to_param }, session: valid_session
        end.to change(Hyrax::CollectionType, :count).by(-1)
      end

      it "redirects to the collection_types list" do
        delete :destroy, params: { id: collection_type.to_param }, session: valid_session
        expect(response).to redirect_to(admin_collection_types_path)
      end
    end
  end
end
