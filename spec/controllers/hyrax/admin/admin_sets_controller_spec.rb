require 'spec_helper'

describe Hyrax::Admin::AdminSetsController do
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
      let!(:admin_set) { create(:admin_set) }

      it 'is unauthorized' do
        get :new
        expect(response).to be_redirect
      end
    end

    describe "#show" do
      context "a public admin set" do
        # Even though the user can view this admin set, the should not be able to view
        # it on the admin page.
        let(:admin_set) { create(:admin_set, :public) }
        it 'is unauthorized' do
          get :show, params: { id: admin_set }
          expect(response).to be_redirect
        end
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
      before do
        controller.admin_set_create_service = service
      end

      context "when it's successful" do
        let(:service) do
          lambda do |admin_set, _|
            admin_set.id = 123
            true
          end
        end
        it 'creates file sets' do
          post :create, params: { admin_set: { title: 'Test title',
                                               description: 'test description',
                                               workflow_name: 'default' } }
          admin_set = assigns(:admin_set)
          expect(response).to redirect_to(edit_admin_admin_set_path(admin_set))
        end
      end

      context "when it fails" do
        let(:service) { ->(_, _) { false } }
        it 'shows the new form' do
          post :create, params: { admin_set: { title: 'Test title',
                                               description: 'test description' } }
          expect(response).to render_template 'new'
        end
      end
    end

    describe "#show" do
      context "when it's successful" do
        let(:admin_set) { create(:admin_set, edit_users: [user]) }
        before do
          create(:work, :public, admin_set: admin_set)
        end

        it 'defines a presenter' do
          get :show, params: { id: admin_set }
          expect(response).to be_success
          expect(assigns[:presenter]).to be_kind_of Hyrax::AdminSetPresenter
          expect(assigns[:presenter].id).to eq admin_set.id
        end
      end
    end

    describe "#edit" do
      let(:admin_set) { create(:admin_set, edit_users: [user]) }
      it 'defines a form' do
        get :edit, params: { id: admin_set }
        expect(response).to be_success
        expect(assigns[:form]).to be_kind_of Hyrax::Forms::AdminSetForm
      end
    end

    describe "#update" do
      let(:admin_set) { create(:admin_set, edit_users: [user]) }
      it 'updates a record' do
        patch :update, params: { id: admin_set,
                                 admin_set: { title: "Improved title" } }
        expect(response).to be_redirect
        expect(assigns[:admin_set].title).to eq ['Improved title']
      end
    end

    describe "#destroy" do
      let(:admin_set) { create(:admin_set, edit_users: [user]) }

      context "with empty admin set" do
        it "deletes the admin set" do
          delete :destroy, params: { id: admin_set }
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(admin_admin_sets_path)
          expect(flash[:notice]).to eq "Administrative set successfully deleted"
          expect(AdminSet.exists?(admin_set.id)).to be false
        end
      end

      context "with a non-empty admin set" do
        let(:work) { create(:generic_work, user: user) }
        before do
          admin_set.members << work
          admin_set.reload
        end
        it "doesn't delete the admin set (or work)" do
          delete :destroy, params: { id: admin_set }
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(admin_admin_set_path(admin_set))
          expect(flash[:alert]).to eq "Administrative set cannot be deleted as it is not empty"
          expect(AdminSet.exists?(admin_set.id)).to be true
          expect(GenericWork.exists?(work.id)).to be true
        end
      end

      context "with the default admin set" do
        let(:admin_set) { create(:admin_set, edit_users: [user], id: AdminSet::DEFAULT_ID) }
        it "doesn't delete the admin set" do
          delete :destroy, params: { id: admin_set }
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(admin_admin_set_path(admin_set))
          expect(flash[:alert]).to eq "Administrative set cannot be deleted as it is the default set"
          expect(AdminSet.exists?(admin_set.id)).to be true
        end
      end
    end
  end
end
