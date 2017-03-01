require 'spec_helper'

# This tests the Hyrax::CurationConcernController module
# which is included into .internal_test_app/app/controllers/hyrax/generic_works_controller.rb
describe Hyrax::GenericWorksController do
  routes { Rails.application.routes }
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
      expect(assigns[:presenter]).to be_instance_of Hyrax::WorkShowPresenter
      expect(flash[:notice]).to eq 'The work is not currently available because it has not yet completed the approval process'
    end
  end

  describe '#show' do
    before do
      create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
    end
    context 'my own private work' do
      let(:work) { create(:private_generic_work, user: user, title: ['test title']) }
      it 'shows me the page' do
        get :show, params: { id: work }
        expect(response).to be_success
        expect(assigns(:presenter)).to be_kind_of Hyrax::WorkShowPresenter
      end

      context "without a referer" do
        it "sets breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.title'), Hyrax::Engine.routes.url_helpers.dashboard_index_path(locale: 'en'))
          get :show, params: { id: work }
          expect(response).to be_successful
        end
      end

      context "with a referer" do
        before do
          request.env['HTTP_REFERER'] = 'http://test.host/foo'
        end

        it "sets breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with('My Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_index_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('My Works', Hyrax::Engine.routes.url_helpers.dashboard_works_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('test title', main_app.hyrax_generic_work_path(work.id, locale: 'en'))
          get :show, params: { id: work }
          expect(response).to be_successful
        end
      end

      context "with a parent work" do
        let(:parent) { create(:generic_work, title: ['Parent Work'], user: user, ordered_members: [work]) }

        before do
          create(:sipity_entity, proxy_for_global_id: parent.to_global_id.to_s)
        end

        it "sets the parent presenter" do
          get :show, params: { id: work, parent_id: parent }
          expect(response).to be_success
          expect(assigns[:parent_presenter]).to be_instance_of Hyrax::WorkShowPresenter
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

    context 'someone elses public work' do
      let(:work) { create(:public_generic_work) }
      context "html" do
        it 'shows me the page' do
          expect(controller). to receive(:additional_response_formats).with(ActionController::MimeResponds::Collector)
          get :show, params: { id: work }
          expect(response).to be_success
        end
      end

      context "ttl" do
        let(:presenter) { double }
        before do
          allow(controller).to receive(:presenter).and_return(presenter)
          allow(presenter).to receive(:export_as_ttl).and_return("ttl graph")
        end

        it 'renders a turtle file' do
          get :show, params: { id: '99999999', format: :ttl }
          expect(response).to be_successful
          expect(response.body).to eq "ttl graph"
          expect(response.content_type).to eq 'text/turtle'
        end
      end
    end

    context 'when I am a repository manager' do
      before { allow(::User.group_service).to receive(:byname).and_return(user.user_key => ['admin']) }
      let(:work) { create(:private_generic_work) }
      it 'someone elses private work should show me the page' do
        get :show, params: { id: work }
        expect(response).to be_success
      end
    end

    context 'with work still in workflow' do
      before do
        allow(controller).to receive(:search_results).and_return([nil, document_list])
      end
      let(:work) { instance_double(GenericWork, id: '99999', to_global_id: '99999') }

      context 'with a user lacking workflow permission' do
        before do
          allow(SolrDocument).to receive(:find).and_return(document)
        end
        let(:document_list) { [] }
        let(:document) { instance_double(SolrDocument, suppressed?: true) }
        it 'shows the unauthorized message' do
          get :show, params: { id: work.id }
          expect(response.code).to eq '401'
          expect(response).to render_template(:unavailable)
          expect(flash[:notice]).to eq 'The work is not currently available because it has not yet completed the approval process'
        end
      end

      context 'with a user granted workflow permission' do
        let(:document_list) { [document] }
        let(:document) { instance_double(SolrDocument) }
        it 'renders without the unauthorized message' do
          get :show, params: { id: work.id }
          expect(response.code).to eq '200'
          expect(response).to render_template(:show)
          expect(flash[:notice]).to be_nil
        end
      end
    end

    context 'when a ObjectNotFoundError is raised' do
      let(:work) { instance_double(GenericWork, id: '99999', to_global_id: '99999') }
      it 'returns 404 page' do
        allow(controller).to receive(:show).and_raise(ActiveFedora::ObjectNotFoundError)
        expect(controller).to receive(:render_404) { controller.render body: nil }
        get :show, params: { id: 'abc123' }
      end
    end
  end

  describe '#new' do
    context 'my work' do
      it 'shows me the page' do
        get :new
        expect(response).to be_success
        expect(assigns[:form]).to be_kind_of Hyrax::GenericWorkForm
        expect(assigns[:form].depositor).to eq user.user_key
        expect(assigns[:curation_concern]).to be_kind_of GenericWork
        expect(assigns[:curation_concern].depositor).to eq user.user_key
        expect(response).to render_template("layouts/hyrax/1_column")
      end
    end
  end

  describe '#create' do
    let(:actor) { double(create: create_status) }
    before do
      allow(Hyrax::CurationConcern).to receive(:actor).and_return(actor)
    end
    let(:create_status) { true }

    context 'when create is successful' do
      let(:work) { stub_model(GenericWork) }
      it 'creates a work' do
        allow(controller).to receive(:curation_concern).and_return(work)
        post :create, params: { generic_work: { title: ['a title'] } }
        expect(response).to redirect_to main_app.hyrax_generic_work_path(work, locale: 'en')
      end
    end

    context 'when create fails' do
      let(:create_status) { false }
      it 'draws the form again' do
        post :create, params: { generic_work: { title: ['a title'] } }
        expect(response.status).to eq 422
        expect(assigns[:form]).to be_kind_of Hyrax::GenericWorkForm
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
          .with(hash_including(:uploaded_files))
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
            GenericWork.create!(title: ['test title']) do |w|
              w.apply_depositor_metadata(user)
            end
          end
          it "records the work" do
            # TODO: ensure the actor stack, called with these params
            # makes one work, two file sets and calls ImportUrlJob twice.
            expect(actor).to receive(:create).with(ActionController::Parameters) do |ac_params|
              expect(ac_params['uploaded_files']).to eq []
              expect(ac_params['remote_files']).to eq browse_everything_params.values.map { |h| ActionController::Parameters.new(h) }
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
      it 'shows me the page' do
        get :edit, params: { id: work }
        expect(response).to be_success
        expect(assigns[:form]).to be_kind_of Hyrax::GenericWorkForm
        expect(response).to render_template("layouts/hyrax/1_column")
      end

      context "without a referer" do
        it "sets breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.title'), Hyrax::Engine.routes.url_helpers.dashboard_index_path(locale: 'en'))
          get :edit, params: { id: work }
          expect(response).to be_successful
        end
      end

      context "with a referer" do
        before do
          request.env['HTTP_REFERER'] = 'http://test.host/foo'
        end

        it "sets breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with('My Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_index_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('My Works', Hyrax::Engine.routes.url_helpers.dashboard_works_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with(work.to_s, Rails.application.routes.url_helpers.hyrax_generic_work_path(work, locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with(I18n.t("hyrax.works.edit.breadcrumb"), String)
          get :edit, params: { id: work }
          expect(response).to be_successful
        end
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
      before { allow(::User.group_service).to receive(:byname).and_return(user.user_key => ['admin']) }
      let(:work) { create(:private_generic_work) }
      it 'someone elses private work should show me the page' do
        get :edit, params: { id: work }
        expect(response).to be_success
      end
    end
  end

  describe '#update' do
    let(:work) { create(:private_generic_work, user: user) }
    let(:visibility_changed) { false }
    let(:actor) { double(update: true) }
    before do
      allow(Hyrax::CurationConcern).to receive(:actor).and_return(actor)
      allow(GenericWork).to receive(:find).and_return(work)
      allow(work).to receive(:visibility_changed?).and_return(visibility_changed)
    end

    it 'updates the work' do
      patch :update, params: { id: work, generic_work: {} }
      expect(response).to redirect_to main_app.hyrax_generic_work_path(work, locale: 'en')
    end

    it "can update file membership" do
      patch :update, params: { id: work, generic_work: { ordered_member_ids: ['foo_123'] } }
      expected_params = { ordered_member_ids: ['foo_123'], remote_files: [], uploaded_files: [] }
      expect(actor).to have_received(:update).with(ActionController::Parameters.new(expected_params).permit!)
    end

    describe 'changing rights' do
      let(:visibility_changed) { true }
      let(:actor) { double(update: true) }

      context 'when there are children' do
        let(:work) { create(:work_with_one_file, user: user) }

        it 'prompts to change the files access' do
          patch :update, params: { id: work, generic_work: {} }
          expect(response).to redirect_to main_app.confirm_hyrax_permission_path(controller.curation_concern, locale: 'en')
        end
      end

      context 'without children' do
        it "doesn't prompt to change the files access" do
          patch :update, params: { id: work, generic_work: {} }
          expect(response).to redirect_to main_app.hyrax_generic_work_path(work, locale: 'en')
        end
      end
    end

    describe 'failure' do
      let(:actor) { double(update: false) }

      it 'renders the form' do
        patch :update, params: { id: work, generic_work: {} }
        expect(assigns[:form]).to be_kind_of Hyrax::GenericWorkForm
        expect(response).to render_template('edit')
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
      before { allow(::User.group_service).to receive(:byname).and_return(user.user_key => ['admin']) }

      let(:work) { create(:private_generic_work) }
      it 'someone elses private work should update the work' do
        patch :update, params: { id: work, generic_work: {} }
        expect(response).to redirect_to main_app.hyrax_generic_work_path(work, locale: 'en')
      end
    end
  end

  describe '#destroy' do
    let(:work_to_be_deleted) { create(:private_generic_work, user: user) }
    let(:parent_collection) { create(:collection) }

    it 'deletes the work' do
      delete :destroy, params: { id: work_to_be_deleted }
      expect(response).to redirect_to Hyrax::Engine.routes.url_helpers.dashboard_works_path(locale: 'en')
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
        expect(response).to redirect_to Hyrax::Engine.routes.url_helpers.dashboard_works_path(locale: 'en')
        expect(parent_collection.reload.members).to eq []
      end
    end

    it "invokes the after_destroy callback" do
      expect(Hyrax.config.callback).to receive(:run)
        .with(:after_destroy, work_to_be_deleted.id, user)
      delete :destroy, params: { id: work_to_be_deleted }
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
      before { allow(::User.group_service).to receive(:byname).and_return(user.user_key => ['admin']) }
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
      expect(response).to be_success
      expect(assigns(:form)).not_to be_blank
    end
  end
end
