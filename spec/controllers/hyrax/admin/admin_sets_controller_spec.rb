RSpec.describe Hyrax::Admin::AdminSetsController do
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

    describe "#show" do
      context "a public admin set" do
        # Even though the user can view this admin set, the should not be able to view
        # it on the admin page.
        let(:admin_set) { create_for_repository(:admin_set, read_groups: ['public']) }

        it 'is unauthorized' do
          get :show, params: { id: admin_set }
          expect(response).to be_redirect
        end
      end
    end

    describe "#files" do
      let(:admin_set) { create_for_repository(:admin_set) }

      it 'is unauthorized' do
        get :files, params: { id: admin_set }, format: :json
        expect(response).to be_unauthorized
      end
    end
  end

  context "as an admin" do
    before do
      sign_in user
      allow(controller).to receive(:authorize!).and_return(true)
    end

    describe "#index" do
      it 'allows an authorized user to view the page' do
        get :index
        expect(response).to be_success
        expect(assigns[:admin_sets]).to be_kind_of Array
      end
    end

    describe "#new" do
      it 'allows an authorized user to view the page' do
        get :new
        expect(response).to be_success
      end
    end

    describe "#create" do
      context "when it's successful" do
        it 'creates file sets' do
          post :create, params: { admin_set: { title: 'Test title',
                                               description: 'test description',
                                               workflow_name: 'default' } }
          admin_set = assigns(:resource)
          expect(response).to redirect_to(edit_admin_admin_set_path(admin_set))
        end
      end

      context "when it fails" do
        let(:service) { ->(**_kargs) { false } }

        before do
          controller.admin_set_create_service = service
        end

        it 'shows the new form' do
          post :create, params: { admin_set: { title: 'Test title',
                                               description: 'test description' } }
          expect(response).to render_template 'new'
        end
      end
    end

    describe "#show" do
      context "when it's successful" do
        let(:admin_set) { create_for_repository(:admin_set, edit_users: [user.user_key]) }

        before do
          create_for_repository(:work, :public, admin_set_id: admin_set.id)
        end

        it 'defines a presenter' do
          get :show, params: { id: admin_set }
          expect(response).to be_success
          expect(assigns[:presenter]).to be_kind_of Hyrax::AdminSetPresenter
          expect(assigns[:presenter].id).to eq admin_set.id.to_s
        end
      end
    end

    describe "#edit" do
      let(:admin_set) { create_for_repository(:admin_set, edit_users: [user.user_key]) }

      it 'defines a form' do
        get :edit, params: { id: admin_set }
        expect(response).to be_success
        expect(assigns[:change_set]).to be_kind_of Hyrax::AdminSetChangeSet
      end
    end

    describe "#files" do
      let(:admin_set) { create_for_repository(:admin_set, edit_users: [user.user_key]) }

      it 'shows a list of member files' do
        get :files, params: { id: admin_set }, format: :json
        expect(response).to be_success
      end
    end

    describe "#update" do
      let(:admin_set) { create_for_repository(:admin_set, edit_users: [user.user_key]) }

      it 'updates a record' do
        patch :update, params: { id: admin_set,
                                 admin_set: { title: "Improved title" } }
        expect(response).to redirect_to(edit_admin_admin_set_path)
        expect(assigns[:resource].title).to eq ['Improved title']
      end
    end

    describe "#destroy" do
      let(:admin_set) { create_for_repository(:admin_set, edit_users: [user.user_key]) }

      context "with empty admin set" do
        it "deletes the admin set" do
          delete :destroy, params: { id: admin_set }
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(admin_admin_sets_path)
          expect(flash[:notice]).to eq "Administrative set successfully deleted"
          expect(Hyrax::Queries.exists?(admin_set.id)).to be false
        end
      end

      context "with a non-empty admin set" do
        let!(:work) { create_for_repository(:work, user: user, admin_set_id: admin_set.id) }

        it "doesn't delete the admin set (or work)" do
          delete :destroy, params: { id: admin_set }
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(admin_admin_set_path(admin_set))
          expect(flash[:alert]).to eq "Administrative set cannot be deleted as it is not empty"
          expect(Hyrax::Queries.exists?(admin_set.id)).to be true
          expect(Hyrax::Queries.exists?(work.id)).to be true
        end
      end

      context "with the default admin set" do
        let(:admin_set) { create_for_repository(:admin_set, edit_users: [user.user_key], id: AdminSet::DEFAULT_ID) }

        it "doesn't delete the admin set" do
          delete :destroy, params: { id: admin_set }
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(admin_admin_set_path(admin_set))
          expect(flash[:alert]).to eq "Administrative set cannot be deleted as it is the default set"
          expect(Hyrax::Queries.exists?(admin_set.id)).to be true
        end
      end
    end
  end
end
