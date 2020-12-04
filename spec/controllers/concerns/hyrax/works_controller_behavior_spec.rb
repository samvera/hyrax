# frozen_string_literal: true

RSpec.describe Hyrax::WorksControllerBehavior, :clean_repo, type: :controller do
  let(:paths) { controller.main_app }
  let(:title) { ['Comet in Moominland'] }
  let(:work)  { FactoryBot.valkyrie_create(:hyrax_work, alternate_ids: [id], title: title) }
  let(:id)    { '123' }

  let(:main_app_routes) do
    ActionDispatch::Routing::RouteSet.new.tap do |r|
      r.draw do # draw minimal routes for this controller mixin
        mount Hyrax::Engine, at: '/'
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

    controller.main_app.instance_variable_set(:@routes, main_app_routes)
    controller.main_app.instance_variable_set(:@helpers, main_app_routes.url_helpers)
  end

  controller(ApplicationController) do
    include Hyrax::WorksControllerBehavior # rubocop:disable RSpec/DescribedClass

    self.curation_concern_type = Hyrax::Test::SimpleWork
    self.search_builder_class  = Wings::WorkSearchBuilder(Hyrax::Test::SimpleWork)
    self.work_form_service     = Hyrax::FormFactory.new
  end

  shared_context 'with a logged in user' do
    let(:user) { create(:user) }

    before { sign_in user }
  end

  describe '#create' do
    it 'redirects to new user login' do
      get :create, params: {}

      expect(response).to redirect_to paths.new_user_session_path(locale: :en)
    end

    context 'with a logged in user' do
      include_context 'with a logged in user'

      before { AdminSet.find_or_create_default_admin_set_id }

      it 'redirects to a new work' do
        get :create, params: { test_simple_work: { title: 'comet in moominland' } }

        expect(response)
          .to redirect_to paths.hyrax_test_simple_work_legacy_path(id: assigns(:curation_concern).id, locale: :en)
      end

      context 'and files' do
        let(:uploads) { FactoryBot.create_list(:uploaded_file, 2, user: user) }

        it 'attaches the files' do
          pending 'it should actually attach the files'
          params = { test_simple_work: { title: 'comet in moominland' },
                     uploaded_files: uploads.map(&:id) }

          get :create, params: params

          expect(flash[:notice]).to be_html_safe
          expect(flash[:notice]).to eq "Your files are being processed by Hyrax in the background. " \
                                       "The metadata and access controls you specified are being applied. " \
                                       "You may need to refresh this page to see these updates."
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
      include_context 'with a logged in user'

      before do
        allow(controller.current_ability)
          .to receive(:can?)
          .with(any_args)
          .and_return true
      end

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
          .to have_attributes(title: work.title.first, version: an_instance_of(String))
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
                              admin_set_id: AdminSet::DEFAULT_ID)
      end

      it 'renders form' do
        get :new

        expect(controller).to render_template('hyrax/base/new')
      end
    end
  end

  describe '#show' do
    shared_examples 'allows show access' do
      it 'allows access' do
        get :show, params: { id: work.id }

        expect(response.status).to eq 200
      end

      it 'resolves ntriples' do
        get :show, params: { id: work.id }, format: :nt

        expect(RDF::Reader.for(:ntriples).new(response.body).objects)
          .to include(RDF::Literal(title.first))
      end

      it 'resolves turtle' do
        get :show, params: { id: work.id }, format: :ttl

        expect(RDF::Reader.for(:ttl).new(response.body).objects)
          .to include(RDF::Literal(title.first))
      end

      it 'resolves jsonld' do
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
      let(:index_document) do
        Wings::ActiveFedoraConverter.convert(resource: work).to_solr.tap do |doc|
          doc[Hydra.config.permissions.read.group] = 'public'
        end
      end

      before { ActiveFedora::SolrService.add(index_document, softCommit: true) }

      it_behaves_like 'allows show access'
    end

    context 'when the user has read access' do
      include_context 'with a logged in user'

      let(:index_document) do
        Wings::ActiveFedoraConverter.convert(resource: work).to_solr.tap do |doc|
          doc[Hydra.config.permissions.read.individual] = [user.user_key]
        end
      end

      before { ActiveFedora::SolrService.add(index_document, softCommit: true) }

      it_behaves_like 'allows show access'
    end
  end

  describe '#manifest' do
    include_context 'with a logged in user'

    it 'resolves json'
  end

  describe '#update' do
    it 'redirects to new user login' do
      patch :update, params: { id: id }

      expect(response).to redirect_to paths.new_user_session_path(locale: :en)
    end

    context 'when the user has edit access' do
      include_context 'with a logged in user'

      before do
        AdminSet.find_or_create_default_admin_set_id

        allow(controller.current_ability)
          .to receive(:can?)
          .with(any_args)
          .and_return true
      end

      it 'redirects to updated work' do
        patch :update, params: { id: id, test_simple_work: { title: 'new title' } }

        expect(response)
          .to redirect_to paths.hyrax_test_simple_work_legacy_path(id: id, locale: :en)
      end

      it 'updates the work metadata' do
        patch :update, params: { id: id, test_simple_work: { title: 'new title' } }

        expect(Hyrax.query_service.find_by(id: id))
          .to have_attributes title: contain_exactly('new title')
      end
    end
  end
end
