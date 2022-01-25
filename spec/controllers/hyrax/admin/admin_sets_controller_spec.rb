# frozen_string_literal: true
RSpec.describe Hyrax::Admin::AdminSetsController do
  routes { Hyrax::Engine.routes }
  let(:admin)   { create(:admin, email: 'admin@example.com') }
  let(:manager) { create(:user, email: 'manager@example.com') }
  let(:creator) { create(:user, email: 'creator@example.com') }
  let(:user)    { create(:user, email: 'user@example.com') }
  let(:ability) { ::Ability.new(manager) }
  let(:ability) { ::Ability.new(creator) }
  let(:ability) { ::Ability.new(user) }

  let!(:admin_set_type) do
    FactoryBot.create(:admin_set_collection_type,
                      manager_user: manager.user_key, creator_user: creator.user_key)
  end

  context "a guest" do
    describe "#index" do
      it 'redirects to user login' do
        get :index
        expect(response).to redirect_to main_app.new_user_session_path
      end
    end

    describe "#new" do
      it 'redirects to user login' do
        get :new
        expect(response).to redirect_to main_app.new_user_session_path
      end
    end
  end

  context "a general registered user" do
    before { sign_in user }

    describe "#index" do
      it 'redirects to collection :index' do
        get :index
        expect(response).to redirect_to(my_collections_path)
      end
    end

    describe "#new" do
      it 'is unauthorized' do
        get :new
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq "You are not authorized to access this page."
      end
    end

    describe "#show" do
      before { controller.instance_variable_set(:@admin_set, admin_set) }

      context "when user has access through public group" do
        # Even though the user can view this admin set, they should not be able to view
        # it on the admin page.
        let(:admin_set) { create(:adminset_lw, with_solr_document: true, with_permission_template: { view_groups: ['public'] }) }

        it 'is unauthorized' do
          get :show, params: { id: admin_set }
          expect(response).to redirect_to root_path
          expect(flash[:alert]).to eq "You are not authorized to access this page."
        end
      end

      context "when user has access through registered group" do
        # Even though the user can view this admin set, the should not be able to view
        # it on the admin page.
        let(:admin_set) { create(:adminset_lw, with_solr_document: true, with_permission_template: { view_groups: ['registered'] }) }

        it 'is unauthorized' do
          get :show, params: { id: admin_set }
          expect(response).to redirect_to root_path
          expect(flash[:alert]).to eq "You are not authorized to access this page."
        end
      end

      context "when user is directly granted view access" do
        # Even though the user can view this admin set, the should not be able to view
        # it on the admin page.
        let(:admin_set) { create(:adminset_lw, with_solr_document: true, with_permission_template: { view_users: [user.user_key] }) }

        before do
          create(:work, :public, admin_set: admin_set)
        end

        it 'defines a presenter' do
          get :show, params: { id: admin_set }
          expect(response).to be_successful
          expect(assigns[:presenter]).to be_kind_of Hyrax::AdminSetPresenter
          expect(assigns[:presenter].id).to eq admin_set.id
        end
      end
    end

    describe "#edit" do
      before do
        sign_in user
      end

      context "when user is directly granted manage access" do
        # Even though the user can view this admin set, the should not be able to view
        # it on the admin page.
        let(:admin_set) { create(:adminset_lw, with_solr_document: true, with_permission_template: { manage_users: [user.user_key] }) }
        let(:admin_set2) { create(:adminset_lw, with_solr_document: true, with_permission_template: true) }

        context 'and user is accessing the managed set' do
          before do
            controller.instance_variable_set(:@admin_set, admin_set)
          end

          it 'defines a form' do
            get :edit, params: { id: admin_set }
            expect(response).to be_successful
            expect(assigns[:form]).to be_kind_of Hyrax::Forms::AdminSetForm
          end
        end

        context 'and user attempts to access another admin set' do
          before do
            controller.instance_variable_set(:@admin_set, admin_set2)
          end

          it 'is unauthorized' do
            get :edit, params: { id: admin_set2 }
            expect(response).to redirect_to root_path
            expect(flash[:alert]).to eq "You are not authorized to access this page."
          end
        end
      end
    end

    describe "#files" do
      let(:admin_set) { create(:admin_set) }

      it 'is unauthorized' do
        get :files, params: { id: admin_set }, format: :json
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq "You are not authorized to access this page."
      end
    end
  end

  ['admin', 'manager', 'creator'].each do |user_type|
    context "as #{user_type == 'admin' ? '' : 'an admin set collection type '}#{user_type}" do
      let(:user) do
        case user_type
        when 'admin'
          admin
        when 'creator'
          creator
        when 'manager'
          manager
        end
      end

      before do
        sign_in user
      end

      describe "#index" do
        it 'redirects to collection :index' do
          get :index
          expect(response).to redirect_to(my_collections_path)
        end
      end

      describe "#new" do
        it 'shows the new form' do
          get :new
          expect(response).to be_successful
          expect(response).to render_template 'new'
        end
      end

      describe "#create" do
        context "when it's successful" do
          before do
            allow(Hyrax::AdminSetCreateService)
              .to receive(:call!).with(any_args).and_return(saved_admin_set)
          end
          let(:admin_set) { FactoryBot.build(:hyrax_admin_set) }
          let(:saved_admin_set) do
            FactoryBot.valkyrie_create(:hyrax_admin_set,
                                       title: 'Test title',
                                       description: 'test description')
          end

          it 'creates admin set' do
            post :create, params: { admin_set: { title: 'Test title',
                                                 description: 'test description',
                                                 workflow_name: 'default' } }
            updated_admin_set = assigns(:admin_set)
            expect(response).to redirect_to(edit_admin_admin_set_path(updated_admin_set))
          end
        end

        context "when it fails" do
          before do
            allow(Hyrax::AdminSetCreateService)
              .to receive(:call!).with(any_args).and_raise(RuntimeError)
          end

          it 'shows the new form' do
            post :create, params: { admin_set: { title: 'Test title',
                                                 description: 'test description' } }
            expect(response).to render_template 'new'
          end
        end
      end

      context "when the #{user_type} creates the admin set" do
        describe "#show" do
          context "when user created the admin set" do
            let(:admin_set) { create(:admin_set, edit_users: [user]) }

            before do
              create(:work, :public, admin_set: admin_set)
            end

            it 'defines a presenter' do
              get :show, params: { id: admin_set }
              expect(response).to be_successful
              expect(assigns[:presenter]).to be_kind_of Hyrax::AdminSetPresenter
              expect(assigns[:presenter].id).to eq admin_set.id
            end
          end
        end

        describe "#edit" do
          let(:admin_set) { create(:admin_set, edit_users: [user]) }

          it 'defines a form' do
            get :edit, params: { id: admin_set }
            expect(response).to be_successful
            expect(assigns[:form]).to be_kind_of Hyrax::Forms::AdminSetForm
          end
        end

        describe "#files" do
          let(:admin_set) { create(:admin_set, edit_users: [user]) }

          it 'shows a list of member files' do
            get :files, params: { id: admin_set }, format: :json
            expect(response).to be_successful
          end
        end

        describe "#update" do
          let(:admin_set) { create(:admin_set, edit_users: [user]) }

          it 'updates a record' do
            patch :update, params: { id: admin_set,
                                     admin_set: { title: "Improved title" } }
            expect(response).to redirect_to(edit_admin_admin_set_path)
            expect(assigns[:admin_set].title).to eq ['Improved title']
          end
        end

        describe "#destroy" do
          let(:admin_set) { create(:admin_set, edit_users: [user]) }

          context "with empty admin set" do
            it "deletes the admin set" do
              controller.request.set_header("HTTP_REFERER", "/admin/admin_sets")
              delete :destroy, params: { id: admin_set }

              expect(response).to have_http_status(:found)
              expect(response).to redirect_to(my_collections_path)
              expect(flash[:notice]).to eq "Administrative set successfully deleted"
              expect(AdminSet.exists?(admin_set.id)).to be false
            end
          end

          context "with empty admin set and referrer from the my/collections dashboard" do
            it "deletes the admin set" do
              controller.request.set_header("HTTP_REFERER", "/my/collections")
              delete :destroy, params: { id: admin_set }

              expect(response).to have_http_status(:found)
              expect(response).to redirect_to(my_collections_path)
              expect(flash[:notice]).to eq "Administrative set successfully deleted"
              expect(AdminSet.exists?(admin_set.id)).to be false
            end
          end

          context "with empty admin set and referrer from the /collections dashboard" do
            it "deletes the admin set" do
              controller.request.set_header("HTTP_REFERER", "/collections")
              delete :destroy, params: { id: admin_set }

              expect(response).to have_http_status(:found)
              expect(response).to redirect_to(dashboard_collections_path)
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
  end
end
