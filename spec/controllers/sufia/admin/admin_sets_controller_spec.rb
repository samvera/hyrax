require 'spec_helper'

describe Sufia::Admin::AdminSetsController do
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
      let(:service) { instance_double(Sufia::AdminSetCreateService) }
      before do
        allow(Sufia::AdminSetCreateService).to receive(:new)
          .with(AdminSet, user)
          .and_return(service)
      end

      context "when it's successful" do
        it 'creates file sets' do
          expect(service).to receive(:create).and_return(true)
          post :create, params: { admin_set: { title: 'Test title',
                                               description: 'test description' } }
          expect(response).to be_redirect
        end
      end

      context "when it fails" do
        it 'shows the new form' do
          expect(service).to receive(:create).and_return(false)
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
          expect(assigns[:presenter]).to be_kind_of Sufia::AdminSetPresenter
          expect(assigns[:presenter].id).to eq admin_set.id
        end
      end
    end

    describe "#edit" do
      let(:admin_set) { create(:admin_set, edit_users: [user]) }
      it 'defines a form' do
        get :edit, params: { id: admin_set }
        expect(response).to be_success
        expect(assigns[:form]).to be_kind_of Sufia::Forms::AdminSetForm
      end
    end

    describe "#update" do
      let(:admin_set) { create(:admin_set, edit_users: [user]) }
      it 'updates a record' do
        # Prevent a save which causes Fedora to complain it doesn't know the referenced node.
        expect_any_instance_of(AdminSet).to receive(:save).and_return(true)
        patch :update, params: { id: admin_set,
                                 admin_set: { title: "Improved title",
                                              thumbnail_id: "mw22v559x" } }
        expect(response).to be_redirect
        expect(assigns[:admin_set].title).to eq ['Improved title']
        expect(assigns[:admin_set].thumbnail_id).to eq 'mw22v559x'
      end
    end
  end
end
