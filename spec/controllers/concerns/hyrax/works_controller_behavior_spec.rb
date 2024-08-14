# frozen_string_literal: true

require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::WorksControllerBehavior, :clean_repo, type: :controller do
  let(:paths) { controller.main_app }
  let(:title) { ['Comet in Moominland'] }
  let(:work)  { FactoryBot.valkyrie_create(:hyrax_work, alternate_ids: [id], title: title) }
  let(:id)    { '123' }

  let(:work_route_path) do
    "#{work.model_name.singular_route_key}_path"
  end

  let(:main_app_routes) do
    ActionDispatch::Routing::RouteSet.new.tap do |r|
      r.draw do # draw minimal routes for this controller mixin
        mount Hyrax::Engine, at: '/'
        namespaced_resources 'hyrax/test/simple_work', except: [:index]
        namespaced_resources 'hyrax/test/simple_work_legacy', except: [:index]
        devise_for :users
        resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog'
      end
    end
  end

  before do
    allow(Hyrax.config)
      .to receive(:registered_curation_concern_types)
      .and_return([work.model_name.name])
    allow(Hyrax::ModelRegistry)
      .to receive(:work_classes)
      .and_return([Hyrax::Test::SimpleWork])

    # NOTE: we can't run jobs that rely on routes (i.e. those that send notifications)
    # from here because of this stubbing. it's proabably best just to not do that
    # anyway. if these tests depend on specific job behavior, they may be testing too
    # much.
    controller.main_app.instance_variable_set(:@routes, main_app_routes)
    controller.main_app.instance_variable_set(:@helpers, main_app_routes.url_helpers)
  end

  controller(ApplicationController) do
    include Hyrax::WorksControllerBehavior # rubocop:disable RSpec/DescribedClass

    self.curation_concern_type = Hyrax::Test::SimpleWork
    self.search_builder_class  = Wings::WorkSearchBuilder(Hyrax::Test::SimpleWork) unless
      Hyrax.config.disable_wings
    self.work_form_service     = Hyrax::FormFactory.new
  end

  shared_context 'with a logged in user' do
    let(:user) { create(:user) }

    before { sign_in user }
  end

  shared_context 'with a user with edit access' do
    include_context 'with a logged in user'

    let(:work) do
      FactoryBot.valkyrie_create(:hyrax_work,
                                 alternate_ids: [id],
                                 title: title,
                                 edit_users: [user])
    end
  end

  describe '#create' do
    it 'redirects to new user login' do
      get :create, params: {}

      expect(response).to redirect_to paths.new_user_session_path(locale: :en)
    end

    context 'with a logged in user' do
      include_context 'with a logged in user'

      before { Hyrax::AdminSetCreateService.find_or_create_default_admin_set }

      it 'redirects to a new work' do
        get :create, params: { test_simple_work: { title: 'comet in moominland' } }

        expect(response)
          .to redirect_to paths.send(work_route_path, id: assigns(:curation_concern).id, locale: :en)
      end

      it 'sets current user as depositor' do
        post :create, params: { test_simple_work: { title: 'comet in moominland' } }

        expect(assigns[:curation_concern].depositor).to eq user.user_key
      end

      it 'grants edit permissions to current user (as depositor)' do
        post :create, params: { test_simple_work: { title: 'comet in moominland' } }

        expect(Hyrax::AccessControlList(assigns[:curation_concern]).permissions)
          .to include(have_attributes(agent: user.user_key, mode: :edit))
      end

      it 'sets workflow state as "deposited"; uses default workflow' do
        post :create, params: { test_simple_work: { title: 'comet in moominland' } }

        expect(Sipity::Entity(assigns[:curation_concern]).workflow_state).to have_attributes(name: "deposited")
      end

      context 'when depositing as a proxy for (on_behalf_of) another user' do
        let(:create_params) { { title: 'comet in moominland', on_behalf_of: target_user.user_key } }
        let(:target_user) { FactoryBot.create(:user) }
        it 'transfers depositor status to proxy target' do
          expect { post :create, params: { test_simple_work: create_params } }
            .to have_enqueued_job(ChangeDepositorEventJob)
          expect(assigns[:curation_concern]).to have_attributes(depositor: target_user.user_key)
          expect(assigns[:curation_concern]).to have_attributes(proxy_depositor: user.user_key)
        end
      end

      context 'when setting visibility' do
        let(:create_params) { { title: 'comet in moominland', visibility: 'open' } }

        it 'can set work to public' do
          post :create, params: { test_simple_work: create_params }

          expect(assigns[:curation_concern]).to have_attributes(visibility: 'open')
        end

        it 'saves the visibility' do
          post :create, params: { test_simple_work: create_params }

          expect(Hyrax::AccessControlList(assigns[:curation_concern]).permissions)
            .to include(have_attributes(mode: :read, agent: 'group/public'))
        end
      end

      context 'when granting additional permissions' do
        let(:create_params) { { title: 'comet in moominland', permissions_attributes: { "0" => { type: 'person', access: 'read', name: 'foo@bar.com' } } } }

        it 'saves the visibility' do
          post :create, params: { test_simple_work: create_params }

          expect(Hyrax::AccessControlList(assigns[:curation_concern]).permissions)
            .to include(have_attributes(mode: :read, agent: 'foo@bar.com'))
        end
      end

      context 'when setting an admin set' do
        let(:admin_set_user) { FactoryBot.create(:user) }

        let(:admin_set) do
          FactoryBot.valkyrie_create(:hyrax_admin_set, :with_permission_template, user: admin_set_user)
        end

        let(:create_params) do
          { title: 'comet in moominland',
            admin_set_id: admin_set.id }
        end

        it "sets the admin set" do
          post :create, params: { test_simple_work: create_params }

          expect(assigns[:curation_concern].admin_set_id).to eq admin_set.id
        end

        it "grants edit access to the manage users" do
          post :create, params: { test_simple_work: create_params }

          expect(assigns[:curation_concern].edit_users.to_a)
            .to include(admin_set_user.user_key)
        end
      end

      context 'when adding a collection' do
        let(:collection) { FactoryBot.valkyrie_create(:hyrax_collection) }

        let(:create_params) do
          { title: 'comet in moominland',
            member_of_collection_ids: [collection.id.to_s] }
        end

        it 'adds to the collection' do
          post :create, params: { test_simple_work: create_params }

          expect(assigns[:curation_concern].member_of_collection_ids)
            .to contain_exactly(collection.id)
        end

        context 'with attributes' do
          let(:create_params) do
            { title: 'comet in moominland',
              member_of_collections_attributes:
                { "0" =>
                 { "id" => collection.id, "_destroy" => "false" } } }
          end

          it 'adds to the collection' do
            post :create, params: { test_simple_work: create_params }

            expect(assigns[:curation_concern].member_of_collection_ids)
              .to contain_exactly(collection.id)
          end
        end

        context 'with both setter styles' do
          let(:other_collection) { FactoryBot.valkyrie_create(:hyrax_collection) }
          let(:create_params) do
            { title: 'comet in moominland',
              member_of_collections_attributes:
                { "0" =>
                 { "id" => other_collection.id, "_destroy" => "false" } },
              member_of_collection_ids: [collection.id] }
          end

          it 'adds to the collection' do
            post :create, params: { test_simple_work: create_params }

            expect(assigns[:curation_concern].member_of_collection_ids)
              .to contain_exactly(collection.id, other_collection.id)
          end
        end
      end

      context 'and files' do
        let(:uploads) { FactoryBot.create_list(:uploaded_file, 2, user: user) }

        it 'attaches the files' do
          params = { test_simple_work: { title: 'comet in moominland' },
                     uploaded_files: uploads.map(&:id) }

          get :create, params: params

          expect(flash[:notice]).to be_html_safe
          expect(flash[:notice]).to eq I18n.t("hyrax.works.create.after_create_html",
                                              application_name: I18n.t('hyrax.product_name', default: 'Hyrax'))
          expect(assigns(:curation_concern)).to have_file_set_members(be_persisted, be_persisted)
        end

        let(:uploads) { FactoryBot.create_list(:uploaded_file, 2, user: user) }

        it 'rejects files from another user' do
          pending 'the controller (NOT the actor stack/transaction!) should validate that the uploader and current user are the same'
          uploads << FactoryBot.create(:uploaded_file)
          params = { test_simple_work: { title: 'comet in moominland' }, uploaded_files: uploads.map(&:id) }

          get :create, params: params

          expect(response.status).to eq 422
        end

        it 'sets the file visibility' do
          params = { test_simple_work: { title: 'comet in moominland',
                                         file_set: [{ uploaded_file_id: uploads.first.id, visibility: 'open' },
                                                    { uploaded_file_id: uploads.second.id, visibility: 'open' }] },
                     uploaded_files: uploads.map(&:id) }

          get :create, params: params

          expect(assigns(:curation_concern)).to have_file_set_members(have_attributes(visibility: 'open'), have_attributes(visibility: 'open'))
        end
      end

      context 'and a parent work' do
        let(:listener) { Hyrax::Specs::AppendingSpyListener.new }
        let(:parent)   { FactoryBot.valkyrie_create(:hyrax_work) }

        let(:params) do
          { test_simple_work: { title: 'comet in moominland' },
            parent_id: parent.id }
        end

        before { Hyrax.publisher.subscribe(listener) }
        after  { Hyrax.publisher.unsubscribe(listener) }

        it 'adds the new work as a member of the parent' do
          post :create, params: params

          expect(Hyrax.query_service.find_by(id: parent.id).member_ids)
            .to contain_exactly(assigns(:curation_concern).id)
        end

        it 'publishes a metadata change event for the parent ' do
          expect { post :create, params: params }
            .to change { listener.object_metadata_updated.map(&:payload) }
            .from(be_empty)
            .to include(match(object: have_attributes(id: parent.id), user: user))
        end
      end

      context 'with invalid form data' do
        let(:work) { FactoryBot.build(:hyrax_work) }

        before do
          allow(controller.class.work_form_service)
            .to receive(:build)
            .and_return(Hyrax::Test::FormWithValidations.new(work))
        end

        it 'gives UNPROCESSABLE ENTITY' do
          get :create, params: { test_simple_work: { title: '' } }

          expect(response.status).to eq 422
        end
      end
    end
  end

  describe '#destroy' do
    it 'redirect to user login' do
      delete :destroy, params: { id: work.id }
      expect(response).to redirect_to paths.new_user_session_path(locale: :en)
    end

    context 'with a logged in user' do
      include_context 'with a logged in user'

      it 'gives 401 unauthorized' do
        delete :destroy, params: { id: work.id }
        expect(response.status).to eq 401
      end
    end

    context 'when the user has edit access' do
      include_context 'with a user with edit access'

      it 'is a success' do
        delete :destroy, params: { id: work.id }

        expect(response.status).to eq 302 # redirect on success
      end

      it 'deletes the work' do
        delete :destroy, params: { id: work.id }

        expect { Hyrax.query_service.find_by(id: work.id) }
          .to raise_error Valkyrie::Persistence::ObjectNotFoundError
      end

      it 'tells the user what they deleted' do
        delete :destroy, params: { id: work.id }

        expect(flash[:notice]).to include work.title.first
      end

      context 'with trophies' do
        before { 3.times { Trophy.create(work_id: work.id) } }

        it 'deletes the trophies' do
          delete :destroy, params: { id: work.id }

          expect(Trophy.where(work_id: work.id.to_s)).to be_empty
        end
      end
    end
  end

  describe '#edit' do
    it 'gives a 404 for a missing object' do
      expect { get :edit, params: { id: 'missing_id' } }
        .to raise_error Hyrax::ObjectNotFoundError
    end

    it 'redirects to new user login' do
      get :edit, params: { id: work.id }

      expect(response).to redirect_to paths.new_user_session_path(locale: :en)
    end

    context 'with a logged in user' do
      include_context 'with a logged in user'

      it 'gives unauthorized' do
        get :edit, params: { id: work.id }

        expect(response.status).to eq 401
      end
    end

    context 'when the user has edit access' do
      include_context 'with a user with edit access'

      it 'is a success' do
        get :edit, params: { id: work.id }

        expect(response.status).to eq 200
      end

      it 'assigns a form with the current work as model' do
        get :edit, params: { id: work.id }

        expect(assigns[:form].model.id).to eq work.id
      end

      it 'renders the form' do
        get :edit, params: { id: work.id }

        expect(controller).to render_template('hyrax/base/edit')
      end

      it 'prepopulates the form' do
        get :edit, params: { id: work.id }

        expect(assigns[:form])
          .to have_attributes(title: work.title, version: an_instance_of(String))
      end

      context 'and the work has member FileSets' do
        include_context 'with a user with edit access'

        let(:work) do
          FactoryBot.valkyrie_create(:hyrax_work,
                                     :with_member_file_sets,
                                     :with_representative,
                                     :with_thumbnail,
                                     edit_users: [user])
        end

        it 'is successful' do
          get :edit, params: { id: work.id }

          expect(response).to be_successful
        end

        it 'populates the form with a file ids' do
          get :edit, params: { id: work.id }

          expect(assigns[:form])
            .to have_attributes(representative_id: work.member_ids.first,
                                thumbnail_id: work.member_ids.first)
        end
      end
    end
  end

  describe '#new' do
    it 'redirect to user login' do
      get :new
      expect(response).to redirect_to paths.new_user_session_path(locale: :en)
    end

    context 'with a logged in user' do
      include_context 'with a logged in user'

      it 'is successful' do
        get :new

        expect(response).to be_successful
      end

      it 'assigns a change_set as the form' do
        get :new

        expect(assigns[:form]).to be_a Valkyrie::ChangeSet
      end

      it 'prepopulates depositor and admin set' do
        get :new

        expect(assigns[:form])
          .to have_attributes(depositor: user.user_key,
                              admin_set_id: Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id.to_s)
      end

      it 'renders form' do
        get :new

        expect(controller).to render_template('hyrax/base/new')
      end

      it 'populates allowed admin sets' do
        admin_set_id = Hyrax::AdminSetCreateService.find_or_create_default_admin_set.id.to_s
        FactoryBot.valkyrie_create(:hyrax_admin_set) # one without deposit access

        get :new

        expect(assigns['admin_set_options'].select_options)
          .to contain_exactly(["Default Admin Set", admin_set_id, { "data-sharing" => true }])
      end
    end
  end

  describe '#show' do
    shared_examples 'allows show access' do
      it 'allows access' do
        get :show, params: { id: work.id }

        expect(response.status).to eq 200
      end

      it 'resolves ntriples', :active_fedora do
        get :show, params: { id: work.id }, format: :nt

        expect(RDF::Reader.for(:ntriples).new(response.body).objects)
          .to include(RDF::Literal(title.first))
      end

      it 'resolves turtle', :active_fedora do
        get :show, params: { id: work.id }, format: :ttl

        expect(RDF::Reader.for(:ttl).new(response.body).objects)
          .to include(RDF::Literal(title.first))
      end

      it 'resolves jsonld', :active_fedora do
        get :show, params: { id: work.id }, format: :jsonld

        expect(RDF::Reader.for(:jsonld).new(response.body).objects)
          .to include(RDF::Literal(title.first))
      end

      it 'resolves json' do
        get :show, params: { id: work.id }, format: :json

        expect(controller).to render_template('hyrax/base/show')
      end
    end

    it 'gives a 404 for a missing object' do
      expect { get :show, params: { id: 'missing_id' } }
        .to raise_error Blacklight::Exceptions::RecordNotFound
    end

    it 'redirects to new user login' do
      get :show, params: { id: work.id }

      expect(response).to redirect_to paths.new_user_session_path(locale: :en)
    end

    context 'when indexed as public' do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :public, alternate_ids: [id], title: title) }

      it_behaves_like 'allows show access'
    end

    context 'when the user has read access' do
      include_context 'with a logged in user'

      let(:work) { FactoryBot.valkyrie_create(:hyrax_work, alternate_ids: [id], title: title, read_users: [user]) }

      it_behaves_like 'allows show access'
    end
  end

  describe '#manifest' do
    include_context 'with a logged in user'

    it 'resolves json'
  end

  describe '#update' do
    it 'redirects to new user login' do
      patch :update, params: { id: work.id }

      expect(response).to redirect_to paths.new_user_session_path(locale: :en)
    end

    context 'when the user has edit access' do
      include_context 'with a user with edit access'

      before { Hyrax::AdminSetCreateService.find_or_create_default_admin_set }

      it 'redirects to updated work' do
        patch :update, params: { id: work.id, test_simple_work: { title: 'new title' } }

        expect(response)
          .to redirect_to paths.send(work_route_path, id: work.id, locale: :en)
      end

      it 'updates the work metadata' do
        patch :update, params: { id: work.id, test_simple_work: { title: 'new title' } }

        expect(Hyrax.query_service.find_by(id: work.id))
          .to have_attributes title: contain_exactly('new title')
      end

      context 'and files' do
        let(:uploads) { FactoryBot.create_list(:uploaded_file, 2, user: user) }

        it 'attaches the files' do
          params = { id: work.id, test_simple_work: { title: 'comet in moominland' },
                     uploaded_files: uploads.map(&:id) }

          get :update, params: params
          expect(assigns(:curation_concern)).to have_file_set_members(be_persisted, be_persisted)
        end

        it 'sets the file visibility' do
          params = { id: work.id,
                     test_simple_work: { title: 'comet in moominland',
                                         file_set: [{ uploaded_file_id: uploads.first.id, visibility: 'open' },
                                                    { uploaded_file_id: uploads.second.id, visibility: 'open' }] },
                     uploaded_files: uploads.map(&:id) }

          get :update, params: params
          expect(assigns(:curation_concern)).to have_file_set_members(have_attributes(visibility: 'open'), have_attributes(visibility: 'open'))
        end
      end

      context 'and editing visibility' do
        let(:update_params) { { title: 'new title', visibility: 'open' } }

        it 'can make work public' do
          patch :update, params: { id: work.id, test_simple_work: update_params }

          expect(Hyrax::VisibilityReader.new(resource: assigns(:curation_concern)).read).to eq 'open'
        end

        it 'saves the visibility' do
          patch :update, params: { id: work.id, test_simple_work: update_params }

          expect(Hyrax::AccessControlList(assigns[:curation_concern]).permissions)
            .to include(have_attributes(mode: :read, agent: 'group/public'))
        end
      end

      context 'and granting additional permissions' do
        let(:update_params) { { title: 'comet in moominland', permissions_attributes: { "0" => { type: 'person', access: 'read', name: 'foo@bar.com' } } } }

        it 'saves the visibility' do
          post :update, params: { id: work.id, test_simple_work: update_params }

          expect(Hyrax::AccessControlList(assigns[:curation_concern]).permissions)
            .to include(have_attributes(mode: :read, agent: 'foo@bar.com'))
        end
      end

      context 'and error occurs' do
        let(:update_params) { { title: 'new title', visibility: 'open' } }

        context 'in form validation' do
          let(:error_msg) { 'FORM VALIDATION FAILED' }
          before do
            allow_any_instance_of(Hyrax::Forms::ResourceForm).to receive(:validate).and_return(false) # rubocop:disable RSpec/AnyInstance
            allow_any_instance_of(Hyrax::Forms::ResourceForm) # rubocop:disable RSpec/AnyInstance
              .to receive_message_chain(:errors, :messages, :values).and_return([error_msg]) # rubocop:disable RSpec/MessageChain
          end

          it 'stays on the edit form and flashes an error message' do
            patch :update, params: { id: work.id, test_simple_work: update_params }

            expect(flash[:error]).to eq error_msg
            expect(response).to render_template(:edit)
          end
        end

        context 'in transactions' do
          let(:error_msg) { 'TRANSACTION FAILED' }
          let(:failure) { Dry::Monads::Failure([error_msg, fake_new_work]) }
          let(:fake_new_work) { instance_double(Hyrax::Test::SimpleWork) }

          before do
            allow_any_instance_of(Hyrax::Transactions::Steps::Save) # rubocop:disable RSpec/AnyInstance
              .to receive(:call).with(any_args).and_return(failure)
          end

          it 'stays on the edit form and flashes an error message' do
            patch :update, params: { id: work.id, test_simple_work: update_params }

            expect(flash[:error]).to eq error_msg
            expect(response).to render_template(:edit)
          end
        end
      end
    end
  end
end
