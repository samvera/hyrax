# This tests the Hyrax::WorksControllerBehavior module
# which is included into .internal_test_app/app/controllers/hyrax/generic_works_controller.rb
RSpec.describe Hyrax::GenericWorksController do
  routes { Rails.application.routes }
  let(:main_app) { Rails.application.routes.url_helpers }
  let(:hyrax) { Hyrax::Engine.routes.url_helpers }
  let(:user) { create(:user) }

  before { sign_in user }

  describe 'integration test for suppressed documents' do
    let(:work) do
      create_for_repository(:work, :public, state: Vocab::FedoraResourceStatus.inactive)
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

  describe '#show' do
    before do
      create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
    end
    context 'my own private work' do
      let(:work) { create_for_repository(:work, :private, user: user, title: ['test title']) }

      it 'shows me the page' do
        get :show, params: { id: work }
        expect(response).to be_success
        expect(assigns(:presenter)).to be_kind_of Hyrax::WorkShowPresenter
      end

      context "without a referer" do
        it "sets breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with("My Dashboard", hyrax.dashboard_path(locale: 'en'))
          get :show, params: { id: work }
          expect(response).to be_successful
        end
      end

      context "with a referer" do
        before do
          request.env['HTTP_REFERER'] = 'http://test.host/foo'
        end

        it "sets breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with('My Dashboard', hyrax.dashboard_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('Your Works', hyrax.my_works_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('test title', main_app.hyrax_generic_work_path(work.id, locale: 'en'))
          get :show, params: { id: work }
          expect(response).to be_successful
          expect(response).to render_template("layouts/hyrax/1_column")
        end
      end

      context "with a parent work" do
        let(:parent) { create_for_repository(:work, title: ['Parent Work'], user: user, member_ids: [work]) }

        before do
          create(:sipity_entity, proxy_for_global_id: parent.to_global_id.to_s)
        end

        it "sets the parent presenter" do
          get :show, params: { id: work, parent_id: parent }
          expect(response).to be_success
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
      let(:work) { create_for_repository(:work, :private) }

      it 'shows unauthorized message' do
        get :show, params: { id: work }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'someone elses public work' do
      let(:work) { create_for_repository(:work, :public) }

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
      let(:work) { create_for_repository(:work, :private) }

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
  end

  describe '#new' do
    context 'my work' do
      it 'shows me the page' do
        get :new
        expect(response).to be_success
        expect(assigns[:change_set]).to be_kind_of GenericWorkChangeSet
        expect(assigns[:change_set].depositor).to eq user.user_key
        expect(assigns[:change_set].resource).to be_kind_of GenericWork
        expect(response).to render_template("layouts/dashboard")
      end
    end
  end

  describe '#create' do
    context 'when create is successful' do
      let(:work) { stub_model(GenericWork) }

      it 'creates a work' do
        allow(GenericWork).to receive(:new).and_return(work)
        post :create, params: { generic_work: { title: ['a title'] } }
        expect(response).to redirect_to main_app.hyrax_generic_work_path(work, locale: 'en')
      end
    end

    context 'when create fails' do
      before do
        allow_any_instance_of(GenericWorkChangeSet).to receive(:validate).and_return(false)
      end

      it 'draws the form again' do
        post :create, params: { generic_work: { title: ['a title'] } }
        expect(response.status).to eq 422
        expect(assigns[:change_set]).to be_kind_of GenericWorkChangeSet
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
      it "attaches files" do
        post :create, params: {
          generic_work: {
            title: ["First title"],
            visibility: 'open'
          },
          uploaded_files: ['777', '888']
        }
        expect(flash[:notice]).to eq "Your files are being processed by Hyrax in the background. " \
                                     "The metadata and access controls you specified are being applied. " \
                                     "You may need to refresh this page to see these updates."
        expect(response).to be_redirect
        id = response.location.gsub("http://test.host/concern/generic_works/", "").gsub(/\?.*$/, '')
        work = Hyrax::Queries.find_by(id: Valkyrie::ID.new(id))
        members = Hyrax::Queries.find_members(resource: work)
        expect(members.size).to eq 2
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
            created_files = Hyrax::Queries.find_all_of_model(model: FileSet)
            expect(created_files.map(&:import_url)).to include(url1, url2)
            expect(created_files.map(&:label)).to include("filepicker-demo.txt.txt", "Getting+Started.pdf")
          end
        end

        context "when a work id is passed" do
          let(:work) do
            create_for_repository(:work, user: user, title: ['test title'])
          end

          it "records the work" do
            post :create, params: {
              selected_files: browse_everything_params,
              uploaded_files: uploaded_files,
              parent_id: work.id,
              generic_work: { title: ['First title'] }
            }
            expect(flash[:notice]).to eq "Your files are being processed by Hyrax in the background. " \
                                         "The metadata and access controls you specified are being applied. " \
                                         "You may need to refresh this page to see these updates."
            expect(response).to be_redirect
            id = response.location.gsub("http://test.host/concern/generic_works/", "").gsub(/\?.*$/, '')
            parent = Hyrax::Queries.find_by(id: work.id)
            members = Hyrax::Queries.find_members(resource: parent)
            expect(members.map(&:id)).to eq Valkyrie::ID.new(id)
          end
        end
      end
    end
  end

  describe '#edit' do
    context 'my own private work' do
      let(:work) { create_for_repository(:work, :private, user: user) }

      it 'shows me the page and sets breadcrumbs' do
        expect(controller).to receive(:add_breadcrumb).with("Home", root_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with("Administration", hyrax.dashboard_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with("Your Works", hyrax.my_works_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with(work.title.first, main_app.hyrax_generic_work_path(work.id, locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with('Edit', main_app.edit_hyrax_generic_work_path(work.id))

        get :edit, params: { id: work }
        expect(response).to be_success
        expect(assigns[:change_set]).to be_kind_of GenericWorkChangeSet
        expect(response).to render_template("layouts/dashboard")
      end
    end

    context 'someone elses private work' do
      routes { Rails.application.class.routes }
      let(:work) { create_for_repository(:work, :private) }

      it 'shows the unauthorized message' do
        get :edit, params: { id: work }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'someone elses public work' do
      let(:work) { create_for_repository(:work, :public) }

      it 'shows the unauthorized message' do
        get :edit, params: { id: work }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'when I am a repository manager' do
      before { allow(::User.group_service).to receive(:byname).and_return(user.user_key => ['admin']) }
      let(:work) { create_for_repository(:work, :private) }

      it 'someone elses private work should show me the page' do
        get :edit, params: { id: work }
        expect(response).to be_success
      end
    end
  end

  describe '#update' do
    let(:work) { create_for_repository(:work) }

    context "when the user has write access to the file" do
      before do
        allow(controller).to receive(:authorize!).with(:update, GenericWork).and_return(true)
      end
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

      context 'when members are set' do
        let(:file_set) { create_for_repository(:file_set) }

        it 'can update file membership' do
          patch :update, params: { id: work, generic_work: { member_ids: [file_set.id.to_s] } }
          expect(work.member_ids).to eq [file_set.id]
        end
      end

      describe 'changing rights' do
        before do
          allow_any_instance_of(GenericWorkChangeSet).to receive(:visibility_changed?).and_return(true)
          allow_any_instance_of(GenericWorkChangeSet).to receive(:permissions_changed?).and_return(false)
        end

        context 'when the work has file sets attached' do
          before do
            allow(Hyrax::Queries).to receive(:find_members).and_return(double(present?: true))
          end
          it 'prompts to change the files access' do
            patch :update, params: { id: work, generic_work: {} }
            expect(response).to redirect_to main_app.confirm_hyrax_permission_path(work, locale: 'en')
          end
        end

        context 'when the work has no file sets' do
          it "doesn't prompt to change the files access" do
            patch :update, params: { id: work, generic_work: {} }
            expect(response).to redirect_to main_app.hyrax_generic_work_path(work, locale: 'en')
          end
        end
      end

      describe 'validation failed' do
        before do
          allow_any_instance_of(GenericWorkChangeSet).to receive(:validate).and_return(false)
        end

        it 'renders the form' do
          patch :update, params: { id: work, generic_work: {} }
          expect(assigns[:change_set]).to be_kind_of GenericWorkChangeSet
          expect(response).to render_template('edit')
        end
      end
    end

    context 'someone elses public work' do
      let(:work) { create_for_repository(:work, :public) }

      it 'shows the unauthorized message' do
        get :update, params: { id: work }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'when I am a repository manager' do
      before { allow(::User.group_service).to receive(:byname).and_return(user.user_key => ['admin']) }

      let(:work) { create_for_repository(:work, :private) }

      it 'someone elses private work should update the work' do
        patch :update, params: { id: work, generic_work: {} }
        expect(response).to redirect_to main_app.hyrax_generic_work_path(work, locale: 'en')
      end
    end
  end

  describe '#destroy' do
    let(:work_to_be_deleted) { create_for_repository(:work, :private, user: user) }
    let(:parent_collection) { create_for_repository(:collection) }

    it 'deletes the work' do
      delete :destroy, params: { id: work_to_be_deleted }
      expect(response).to redirect_to Hyrax::Engine.routes.url_helpers.my_works_path(locale: 'en')
      expect(Hyrax::Queries).not_to exist(work_to_be_deleted.id)
    end

    it "invokes the after_destroy callback" do
      expect(Hyrax.config.callback).to receive(:run)
        .with(:after_destroy, work_to_be_deleted.id, user)
      delete :destroy, params: { id: work_to_be_deleted }
    end

    context 'someone elses public work' do
      let(:work_to_be_deleted) { create_for_repository(:work, :private) }

      it 'shows unauthorized message' do
        delete :destroy, params: { id: work_to_be_deleted }
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    context 'when I am a repository manager' do
      let(:work_to_be_deleted) { create_for_repository(:work, :private) }

      before { allow(::User.group_service).to receive(:byname).and_return(user.user_key => ['admin']) }

      it 'someone elses private work should delete the work' do
        delete :destroy, params: { id: work_to_be_deleted }
        expect(Hyrax::Queries).not_to exist(work_to_be_deleted.id)
      end
    end
  end

  describe '#file_manager' do
    let(:work) { create_for_repository(:work, :private, user: user) }

    before do
      create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
    end
    it "is successful" do
      get :file_manager, params: { id: work.id }
      expect(response).to be_success
      expect(assigns(:change_set)).not_to be_blank
    end
  end
end
