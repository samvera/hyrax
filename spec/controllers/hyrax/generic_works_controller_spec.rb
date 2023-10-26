# frozen_string_literal: true
# This tests the Hyrax::WorksControllerBehavior module
require 'hyrax/specs/spy_listener'

RSpec.describe Hyrax::GenericWorksController, :active_fedora do
  routes { Rails.application.routes }
  let(:main_app) { Rails.application.routes.url_helpers }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }
  let(:user) { create(:user) }

  before { sign_in user }

  describe 'integration test for suppressed documents' do
    let(:work) do
      create(:work, :public, state: Vocab::FedoraResourceStatus.inactive)
    end

    before do
      create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
    end

    it 'renders the unavailable message because it is in workflow' do
      get :show, params: { id: work }
      expect(response.code).to eq '401'
      expect(response).to render_template(:unavailable)
      expect(assigns[:presenter]).to be_instance_of Hyrax::GenericWorkPresenter
      expect(flash[:notice]).to eq 'The work is not currently available because it has not yet completed the approval process'
    end
  end

  describe 'integration test for depositor of a suppressed documents without a workflow role' do
    let(:work) do
      create(:work, :public, state: Vocab::FedoraResourceStatus.inactive, user: user)
    end

    before do
      create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
    end

    it 'renders without the unauthorized message' do
      get :show, params: { id: work.id }
      expect(response.code).to eq '200'
      expect(response).to render_template(:show)
      expect(assigns[:presenter]).to be_instance_of Hyrax::GenericWorkPresenter
      expect(flash[:notice]).to be_nil
    end
  end

  describe '#show' do
    before do
      create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
    end

    context 'while logged out' do
      let(:work) { create(:public_generic_work, user: user, title: ['public thing']) }

      before { sign_out user }

      context "without a referer" do
        it "sets breadcrumbs with complete path" do
          expect(controller).to receive(:add_breadcrumb).with('Home', main_app.root_path(locale: 'en'))
          expect(controller).not_to receive(:add_breadcrumb).with('Dashboard', hyrax.dashboard_path(locale: 'en'))
          expect(controller).not_to receive(:add_breadcrumb).with('Your Works', hyrax.my_works_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('public thing', main_app.hyrax_generic_work_path(work.id, locale: 'en'))
          get :show, params: { id: work }
          expect(response).to be_successful
          expect(response).to render_template("layouts/hyrax/1_column")
        end
      end

      context "with a referer" do
        before do
          request.env['HTTP_REFERER'] = 'http://test.host/foo'
        end

        it "sets breadcrumbs to authorized pages" do
          expect(controller).to receive(:add_breadcrumb).with('Home', main_app.root_path(locale: 'en'))
          expect(controller).not_to receive(:add_breadcrumb).with('Dashboard', hyrax.dashboard_path(locale: 'en'))
          expect(controller).not_to receive(:add_breadcrumb).with('Your Works', hyrax.my_works_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('public thing', main_app.hyrax_generic_work_path(work.id, locale: 'en'))
          get :show, params: { id: work }
          expect(response).to be_successful
          expect(response).to render_template("layouts/hyrax/1_column")
        end
      end
    end

    context 'my own private work' do
      let(:work) { create(:private_generic_work, user: user, title: ['test title']) }

      it 'shows me the page' do
        get :show, params: { id: work }
        expect(response).to be_successful
        expect(assigns(:presenter)).to be_kind_of Hyrax::WorkShowPresenter
      end

      context "without a referer" do
        it "sets breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('Dashboard', hyrax.dashboard_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('Works', hyrax.my_works_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('test title', main_app.hyrax_generic_work_path(work.id, locale: 'en'))
          get :show, params: { id: work }
          expect(response).to be_successful
        end
      end

      context "with a referer" do
        before do
          request.env['HTTP_REFERER'] = 'http://test.host/foo'
        end

        it "sets breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('Dashboard', hyrax.dashboard_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('Works', hyrax.my_works_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('test title', main_app.hyrax_generic_work_path(work.id, locale: 'en'))
          get :show, params: { id: work }
          expect(response).to be_successful
          expect(response).to render_template("layouts/hyrax/1_column")
        end
      end

      context "with a parent work" do
        let(:parent) { create(:generic_work, title: ['Parent Work'], user: user, ordered_members: [work]) }

        before do
          create(:sipity_entity, proxy_for_global_id: parent.to_global_id.to_s)
        end

        it "sets the parent presenter" do
          get :show, params: { id: work, parent_id: parent }
          expect(response).to be_successful
          expect(assigns[:parent_presenter]).to be_instance_of Hyrax::GenericWorkPresenter
        end
      end

      context "with an endnote file" do
        let(:disposition)  { response.header.fetch("Content-Disposition") }
        let(:content_type) { response.header.fetch("Content-Type") }

        render_views

        it 'downloads the file' do
          get :show, params: { id: work, format: 'endnote' }
          expect(response).to be_successful
          expect(disposition).to include("attachment")
          expect(content_type).to eq("application/x-endnote-refer")
          expect(response.body).to include("%T test title")
        end
      end
    end

    context 'someone elses private work' do
      let(:work) { create(:private_generic_work) }

      it 'shows unauthorized message' do
        get :show, params: { id: work }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'someone else\'s public work' do
      let(:work) { create(:public_generic_work) }

      context "html" do
        it 'shows me the page' do
          expect(controller). to receive(:additional_response_formats).with(ActionController::MimeResponds::Collector)
          get :show, params: { id: work }
          expect(response).to be_successful
        end
      end

      context "ttl" do
        let(:presenter) do
          double("Presenter Double",
                 export_as_ttl: 'ttl graph',
                 'editor?': true,
                 to_model: stub_model(GenericWork),
                 'valkyrie_presenter?': false)
        end

        before do
          allow(controller).to receive(:presenter).and_return(presenter)
        end

        it 'renders a turtle file' do
          get :show, params: { id: '99999999', format: :ttl }

          expect(response).to be_successful
          expect(response.body).to eq "ttl graph"
          expect(response.media_type).to eq 'text/turtle'
        end
      end
    end

    context 'when I am a repository manager' do
      before { ::User.group_service.add(user: user, groups: ['admin']) }
      let(:work) { create(:private_generic_work) }

      it 'someone elses private work should show me the page' do
        get :show, params: { id: work }
        expect(response).to be_successful
      end
    end

    context 'with work still in workflow' do
      before do
        allow(controller).to receive(:search_results).and_return([nil, document_list])
      end
      let(:work) { instance_double(GenericWork, id: '99999', to_global_id: '99999') }

      context 'with a user lacking both workflow permission and read access' do
        before do
          allow(SolrDocument).to receive(:find).and_return(document)
          allow(controller.current_ability).to receive(:can?).with(:read, document).and_return(false)
        end
        let(:document_list) { [] }
        let(:document) { instance_double(SolrDocument, suppressed?: true) }

        it 'shows the unauthorized message' do
          get :show, params: { id: work.id }
          expect(response.code).to eq '401'
          expect(response).to render_template(:unauthorized)
        end

        context 'with a user who lacks workflow permission but has read access' do
          before do
            allow(SolrDocument).to receive(:find).and_return(document)
            allow(controller.current_ability).to receive(:can?).with(:read, document).and_return(true)
          end
          let(:document_list) { [] }
          let(:document) { instance_double(SolrDocument, suppressed?: true) }

          it 'shows the unavailable message' do
            get :show, params: { id: work.id }
            expect(response.code).to eq '401'
            expect(response).to render_template(:unavailable)
            expect(flash[:notice]).to eq 'The work is not currently available because it has not yet completed the approval process'
          end
        end
      end

      context 'with a user granted workflow permission' do
        let(:document) { SolrDocument.new(id: work.id, has_model_ssim: ["GenericWork"]) }
        let(:document_list) { [document] }

        it 'renders without the unauthorized message' do
          get :show, params: { id: work.id }
          expect(response.code).to eq '200'
          expect(response).to render_template(:show)
          expect(flash[:notice]).to be_nil
        end
      end
    end
  end

  describe '#new' do
    context 'my work' do
      it 'shows me the page' do
        get :new
        expect(response).to be_successful
        expect(assigns[:form]).to be_kind_of Hyrax::GenericWorkForm
        expect(assigns[:form].depositor).to eq user.user_key
        expect(assigns[:curation_concern]).to be_kind_of GenericWork
        expect(assigns[:curation_concern].depositor).to eq user.user_key
        expect(response).to render_template("layouts/hyrax/dashboard")
      end
    end
  end

  describe '#create' do
    let(:actor) { double(create: create_status) }
    let(:create_status) { true }

    before do
      allow(Hyrax::CurationConcern).to receive(:actor).and_return(actor)
    end

    context 'when create is successful' do
      let(:work) { stub_model(GenericWork) }

      it 'creates a work' do
        allow(controller).to receive(:curation_concern).and_return(work)
        post :create, params: { generic_work: { title: ['a title'] } }
        expect(response).to redirect_to main_app.hyrax_generic_work_path(work, locale: 'en')
      end
    end

    context 'when create fails' do
      let(:work) { create(:work) }
      let(:create_status) { false }

      it 'draws the form again' do
        post :create, params: { generic_work: { title: ['a title'] } }
        expect(response.status).to eq 422
        expect(assigns[:form]).to be_kind_of Hyrax::Forms::FailedSubmissionFormWrapper
        expect(response).to render_template 'new'
      end
    end

    context 'when not authorized' do
      before { allow(controller.current_ability).to receive(:can?).and_return(false) }

      it 'shows the unauthorized message' do
        post :create, params: { generic_work: { title: ['a title'] } }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context "with files" do
      let(:actor) { double('An actor') }
      let(:work) { create(:work) }

      before do
        allow(controller).to receive(:actor).and_return(actor)
        # Stub out the creation of the work so we can redirect somewhere
        allow(controller).to receive(:curation_concern).and_return(work)
      end

      it "attaches files" do
        expect(actor).to receive(:create)
          .with(Hyrax::Actors::Environment) do |env|
            expect(env.attributes.keys).to include('uploaded_files')
          end
                     .and_return(true)
        post :create, params: {
          generic_work: {
            title: ["First title"],
            visibility: 'open'
          },
          uploaded_files: ['777', '888']
        }
        expect(flash[:notice]).to be_html_safe
        expect(flash[:notice]).to eq "Your files are being processed by Hyrax in the background. " \
                                     "The metadata and access controls you specified are being applied. " \
                                     "You may need to refresh this page to see these updates."
        expect(response).to redirect_to main_app.hyrax_generic_work_path(work, locale: 'en')
      end

      context "from browse everything" do
        let(:url1) { "https://dl.dropbox.com/fake/blah-blah.filepicker-demo.txt.txt" }
        let(:url2) { "https://dl.dropbox.com/fake/blah-blah.Getting%20Started.pdf" }
        let(:browse_everything_params) do
          { "0" => { "url" => url1,
                     "expires" => "2014-03-31T20:37:36.214Z",
                     "file_name" => "filepicker-demo.txt.txt" },
            "1" => { "url" => url2,
                     "expires" => "2014-03-31T20:37:36.731Z",
                     "file_name" => "Getting+Started.pdf" } }.with_indifferent_access
        end
        let(:uploaded_files) do
          browse_everything_params.values.map { |v| v['url'] }
        end

        context "For a batch upload" do
          # TODO: move this to batch_uploads controller
          it "ingests files from provide URLs" do
            skip "Creating a FileSet without a parent work is not yet supported"
            expect(ImportUrlJob).to receive(:perform_later).twice
            expect do
              post :create, params: { selected_files: browse_everything_params, file_set: {} }
            end.to change(FileSet, :count).by(2)
            created_files = FileSet.all
            expect(created_files.map(&:import_url)).to include(url1, url2)
            expect(created_files.map(&:label)).to include("filepicker-demo.txt.txt", "Getting+Started.pdf")
          end
        end

        context "when a work id is passed" do
          let(:work) do
            create(:work, user: user, title: ['test title'])
          end

          it "records the work" do
            # TODO: ensure the actor stack, called with these params
            # makes one work, two file sets and calls ImportUrlJob twice.
            expect(actor).to receive(:create).with(Hyrax::Actors::Environment) do |env|
              expect(env.attributes['uploaded_files']).to eq []
              expect(env.attributes['remote_files']).to eq browse_everything_params.values
            end

            post :create, params: {
              selected_files: browse_everything_params,
              uploaded_files: uploaded_files,
              parent_id: work.id,
              generic_work: { title: ['First title'] }
            }
            expect(flash[:notice]).to eq "Your files are being processed by Hyrax in the background. " \
                                         "The metadata and access controls you specified are being applied. " \
                                         "You may need to refresh this page to see these updates."
            expect(response).to redirect_to main_app.hyrax_generic_work_path(work, locale: 'en')
          end
        end
      end
    end
  end

  describe '#edit' do
    context 'my own private work' do
      let(:work) { create(:private_generic_work, user: user) }

      it 'shows me the page and sets breadcrumbs' do
        expect(controller).to receive(:add_breadcrumb).with("Home", root_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with("Dashboard", hyrax.dashboard_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with("Works", hyrax.my_works_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with(work.title.first, main_app.hyrax_generic_work_path(work.id, locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Edit', main_app.edit_hyrax_generic_work_path(work.id))

        get :edit, params: { id: work }
        expect(response).to be_successful
        expect(assigns[:form]).to be_kind_of Hyrax::GenericWorkForm
        expect(response).to render_template("layouts/hyrax/dashboard")
      end
    end

    context 'someone elses private work' do
      routes { Rails.application.class.routes }
      let(:work) { create(:private_generic_work) }

      it 'shows the unauthorized message' do
        get :edit, params: { id: work }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'someone elses public work' do
      let(:work) { create(:public_generic_work) }

      it 'shows the unauthorized message' do
        get :edit, params: { id: work }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'when I am a repository manager' do
      before { ::User.group_service.add(user: user, groups: ['admin']) }

      let(:work) { create(:private_generic_work) }

      it 'someone elses private work should show me the page' do
        get :edit, params: { id: work }
        expect(response).to be_successful
      end
    end
  end

  describe '#update' do
    let(:work) { FactoryBot.create(:work, :public) }

    context "when the user has write access to the file" do
      let(:work) { FactoryBot.create(:work, :public, user: user) }
      let(:file_set) { FactoryBot.create(:file_set, user: user) }

      context "when the work has no file sets" do
        it 'updates the work' do
          patch :update, params: { id: work, generic_work: {} }
          expect(response).to redirect_to main_app.hyrax_generic_work_path(work, locale: 'en')
        end
      end

      context "when the work has file sets attached" do
        before do
          allow(work).to receive(:file_sets).and_return(double(present?: true))
        end
        it 'updates the work' do
          patch :update, params: { id: work, generic_work: {} }
          expect(response).to redirect_to main_app.hyrax_generic_work_path(work, locale: 'en')
        end
      end

      it "can update file membership" do
        patch :update, params: { id: work, generic_work: { ordered_member_ids: [file_set.id] } }
        expect(work.reload.ordered_members.to_a).to contain_exactly(file_set)
      end

      describe 'changing rights' do
        context 'when the work has file sets attached' do
          before do
            allow(GenericWork).to receive(:find).and_return(work)
            allow(work).to receive(:file_sets).and_return(double(present?: true))
          end

          it 'prompts to change the files access' do
            patch :update, params: { id: work, generic_work: { visibility: 'restricted' } }
            expect(response).to redirect_to hyrax.confirm_access_permission_path(controller.curation_concern, locale: 'en')
          end
        end

        context 'when the work has no file sets' do
          it "doesn't prompt to change the files access" do
            patch :update, params: { id: work, generic_work: {} }
            expect(response).to redirect_to main_app.hyrax_generic_work_path(work, locale: 'en')
          end
        end
      end

      describe 'update failed' do
        let(:actor) { double(update: false) }

        before { allow(Hyrax::CurationConcern).to receive(:actor).and_return(actor) }

        it 'renders the form' do
          patch :update, params: { id: work.id, generic_work: {} }
          expect(assigns[:form]).to be_kind_of Hyrax::GenericWorkForm
          expect(response).to render_template('edit')
        end
      end
    end

    context 'someone elses public work' do
      let(:work) { create(:public_generic_work) }

      it 'shows the unauthorized message' do
        get :update, params: { id: work }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'when I am a repository manager' do
      before { ::User.group_service.add(user: user, groups: ['admin']) }
      let(:work) { create(:private_generic_work) }

      it 'someone elses private work should update the work' do
        patch :update, params: { id: work, generic_work: {} }
        expect(response).to redirect_to main_app.hyrax_generic_work_path(work, locale: 'en')
      end
    end
  end

  describe '#destroy' do
    let(:work_to_be_deleted) { create(:private_generic_work, user: user) }
    let(:parent_collection) { build(:collection_lw) }

    let(:listener) { Hyrax::Specs::SpyListener.new }

    before { Hyrax.publisher.subscribe(listener) }
    after  { Hyrax.publisher.unsubscribe(listener) }

    it 'deletes the work' do
      delete :destroy, params: { id: work_to_be_deleted }
      expect(response).to redirect_to Hyrax::Engine.routes.url_helpers.my_works_path(locale: 'en')
      expect(GenericWork).not_to exist(work_to_be_deleted.id)
    end

    context "when work is a member of a collection" do
      before do
        parent_collection.members = [work_to_be_deleted]
        parent_collection.save!
      end
      it 'deletes the work and updates the parent collection' do
        delete :destroy, params: { id: work_to_be_deleted }
        expect(GenericWork).not_to exist(work_to_be_deleted.id)
        expect(response).to redirect_to Hyrax::Engine.routes.url_helpers.my_works_path(locale: 'en')
        expect(parent_collection.reload.members).to eq []
      end
    end

    it "invokes the after_destroy callback" do
      expect { delete :destroy, params: { id: work_to_be_deleted } }
        .to change { listener.object_deleted&.payload }
        .to eq id: work_to_be_deleted.id, user: user
    end

    context 'someone elses public work' do
      let(:work_to_be_deleted) { create(:private_generic_work) }

      it 'shows unauthorized message' do
        delete :destroy, params: { id: work_to_be_deleted }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'when I am a repository manager' do
      let(:work_to_be_deleted) { create(:private_generic_work) }

      before { ::User.group_service.add(user: user, groups: ['admin']) }

      it 'someone elses private work should delete the work' do
        delete :destroy, params: { id: work_to_be_deleted }
        expect(GenericWork).not_to exist(work_to_be_deleted.id)
      end
    end
  end

  describe '#file_manager' do
    let(:work) { create(:private_generic_work, user: user) }

    before do
      create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
    end
    it "is successful" do
      get :file_manager, params: { id: work.id }
      expect(response).to be_successful
      expect(assigns(:form)).not_to be_blank
    end
  end

  describe '#manifest' do
    let(:work) { create(:work_with_one_file, user: user) }
    let(:file_set) { work.ordered_members.to_a.first }
    let(:manifest_factory) { double(to_h: { test: 'manifest' }) }

    before do
      Hydra::Works::AddFileToFileSet.call(file_set,
                                          File.open(fixture_path + '/world.png'),
                                          :original_file)
      allow(IIIFManifest::ManifestFactory).to receive(:new)
        .with(Hyrax::IiifManifestPresenter)
        .and_return(manifest_factory)
    end

    it 'uses the configured service' do
      custom_builder = double(manifest_for: { test: 'cached manifest' })
      allow(described_class).to receive(:iiif_manifest_builder).and_return(custom_builder)

      get :manifest, params: { id: work, format: :json }
      expect(response.body).to eq "{\"test\":\"cached manifest\"}"
    end

    it "produces a manifest for a json request" do
      get :manifest, params: { id: work, format: :json }
      expect(response.body).to eq "{\"test\":\"manifest\"}"
    end

    it "produces a manifest for a html request" do
      get :manifest, params: { id: work, format: :html }
      expect(response.body).to eq "{\"test\":\"manifest\"}"
    end

    describe "when there are html tags in the labels or description" do
      let(:manifest_factory) { double(to_h: { label: "The title<img src=xx:x onerror=eval('\x61ler\x74(1)') />", description: ["Some description <script>something</script> here..."] }) }

      it "sanitizes the labels and description" do
        get :manifest, params: { id: work, format: :json }
        expect(response.body).to include "{\"label\":\"The title\\u003cimg\\u003e\",\"description\":[\"Some description  here...\"]}"
      end
    end
  end
end
