# frozen_string_literal: true

RSpec.describe Hyrax::FileSetsController do
  routes      { Rails.application.routes }
  let(:user)  { FactoryBot.create(:user) }
  let(:actor) { controller.send(:actor) }

  context "when signed in" do
    before { sign_in user }

    describe "#destroy" do
      context "file_set with a parent" do
        let(:file_set) { FactoryBot.create(:file_set, user: user) }
        let(:work) { FactoryBot.create(:work, title: ['test title'], user: user) }

        before do
          work.ordered_members << file_set
          work.save!
        end

        it "deletes the file" do
          expect(ContentDeleteEventJob).to receive(:perform_later).with(file_set.id, user)

          expect { delete :destroy, params: { id: file_set } }
            .to change { FileSet.exists?(file_set.id) }
            .from(true)
            .to(false)

          expect(response).to redirect_to main_app.hyrax_generic_work_path(work, locale: 'en')
        end
      end
    end

    describe "#edit" do
      let(:parent) { FactoryBot.create(:work, :public, user: user) }

      let(:file_set) do
        FactoryBot.create(:file_set, user: user).tap do |file_set|
          parent.ordered_members << file_set
          parent.save!
        end
      end

      before do
        binary = StringIO.new("hey")
        Hydra::Works::AddFileToFileSet.call(file_set, binary, :original_file, versioning: true)
        request.env['HTTP_REFERER'] = 'http://test.host/foo'
      end

      it "sets the breadcrumbs and versions presenter" do
        app_helpers    = Rails.application.routes.url_helpers
        engine_helpers = Hyrax::Engine.routes.url_helpers

        expect(controller)
          .to receive(:add_breadcrumb)
          .with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
        expect(controller)
          .to receive(:add_breadcrumb)
          .with(I18n.t('hyrax.dashboard.title'), engine_helpers.dashboard_path(locale: 'en'))
        expect(controller)
          .to receive(:add_breadcrumb)
          .with(I18n.t('hyrax.dashboard.my.works'), engine_helpers.my_works_path(locale: 'en'))
        expect(controller)
          .to receive(:add_breadcrumb)
          .with(I18n.t('hyrax.file_set.browse_view'), app_helpers.hyrax_file_set_path(file_set, locale: 'en'))

        get :edit, params: { id: file_set }

        expect(response).to be_successful
        expect(assigns[:file_set]).to eq file_set
        expect(assigns[:version_list]).to be_kind_of Hyrax::VersionListPresenter
        expect(assigns[:parent]).to eq parent
        expect(response).to render_template(:edit)
        expect(response).to render_template('dashboard')
      end
    end

    describe "#update" do
      let(:parent) { FactoryBot.create(:work, :public, user: user) }

      let(:file_set) do
        FactoryBot.create(:file_set, user: user, title: ['test title']).tap do |file_set|
          parent.ordered_members << file_set
          parent.save!
        end
      end

      context "when updating metadata" do
        it "spawns a content update event job" do
          expect do
            post :update, params: {
              id: file_set,
              file_set: {
                title: ['new_title'],
                keyword: [''],
                permissions_attributes: [{ type: 'person',
                                           name: 'archivist1',
                                           access: 'edit' }]
              }
            }
          end.to have_enqueued_job(ContentUpdateEventJob).exactly(:once)

          expect(response)
            .to redirect_to main_app.hyrax_file_set_path(file_set, locale: 'en')
          expect(assigns[:file_set].modified_date)
            .not_to be file_set.modified_date
        end
      end

      context "when updating the attached file direct upload" do
        let(:actor) { double }

        before do
          allow(Hyrax::Actors::FileActor).to receive(:new).and_return(actor)
        end

        it "spawns a ContentNewVersionEventJob", perform_enqueued: [IngestJob] do
          expect(ContentNewVersionEventJob).to receive(:perform_later).with(file_set, user)
          expect(actor).to receive(:ingest_file).with(JobIoWrapper).and_return(true)
          file = fixture_file_upload('/world.png', 'image/png')
          post :update, params: { id: file_set, filedata: file, file_set: { keyword: [''], permissions_attributes: [{ type: 'person', name: 'archivist1', access: 'edit' }] } }
          post :update, params: { id: file_set, file_set: { files: [file], keyword: [''], permissions_attributes: [{ type: 'person', name: 'archivist1', access: 'edit' }] } }
        end
      end

      context "when updating the attached file already uploaded" do
        let(:actor) { double(Hyrax::Actors::FileActor) }

        before do
          allow(Hyrax::Actors::FileActor).to receive(:new).and_return(actor)
        end

        it "spawns a ContentNewVersionEventJob", perform_enqueued: [IngestJob] do
          expect(actor)
            .to receive(:ingest_file)
            .with(JobIoWrapper)
            .and_return(true)
          expect(ContentNewVersionEventJob)
            .to receive(:perform_later)
            .with(file_set, user)

          file = fixture_file_upload('/world.png', 'image/png')
          allow(Hyrax::UploadedFile)
            .to receive(:find)
            .with(["1"])
            .and_return([file])

          post :update, params: { id: file_set, files_files: ["1"] }

          expect(assigns[:file_set].modified_date)
            .not_to be file_set.modified_date
          expect(assigns[:file_set].title)
            .to contain_exactly(*file_set.title)
        end
      end

      context "with two existing versions from different users", :perform_enqueued do
        let(:file1)       { "world.png" }
        let(:file2)       { "image.jpg" }
        let(:second_user) { create(:user) }
        let(:version1)    { "version1" }
        let(:actor1)      { Hyrax::Actors::FileSetActor.new(file_set, user) }
        let(:actor2)      { Hyrax::Actors::FileSetActor.new(file_set, second_user) }

        before do
          ActiveJob::Base.queue_adapter.filter = [IngestJob]
          actor1.create_content(fixture_file_upload(file1))
          actor2.create_content(fixture_file_upload(file2))
        end

        describe "restoring a previous version" do
          context "as the first user" do
            before do
              sign_in user
              post :update, params: { id: file_set, revision: version1 }
            end

            let(:restored_content) { file_set.reload.original_file }
            let(:versions)         { restored_content.versions }
            let(:latest_version)   { Hyrax::VersioningService.latest_version_of(restored_content) }

            it "restores the first versions's content and metadata" do
              # expect(restored_content.mime_type).to eq "image/png"
              expect(restored_content).to be_a(Hydra::PCDM::File)
              expect(restored_content.original_name).to eq file1
              expect(versions.all.count).to eq 3
              expect(versions.last.label).to eq latest_version.label
              expect(Hyrax::VersionCommitter.where(version_id: versions.last.uri).pluck(:committer_login))
                .to eq [user.user_key]
            end
          end

          context "as a user without edit access" do
            before { sign_in second_user }

            it "is unauthorized" do
              post :update, params: { id: file_set, revision: version1 }
              expect(response.code).to eq '401'
              expect(response).to render_template 'unauthorized'
              expect(response).to render_template('dashboard')
            end
          end
        end
      end

      it "adds new groups and users" do
        post :update, params: {
          id: file_set,
          file_set: { keyword: [''],
                      permissions_attributes: [
                        { type: 'person', name: 'user1', access: 'edit' },
                        { type: 'group', name: 'group1', access: 'read' }
                      ] }
        }

        expect(assigns[:file_set])
          .to have_attributes(read_groups: contain_exactly("group1"),
                              edit_users: include("user1", user.user_key))
      end

      it "updates existing groups and users" do
        file_set.edit_groups = ['group3']
        file_set.save

        post :update, params: {
          id: file_set,
          file_set: { keyword: [''],
                      permissions_attributes: [
                        { id: file_set.permissions.last.id, type: 'group', name: 'group3', access: 'read' }
                      ] }
        }

        expect(assigns[:file_set].read_groups).to contain_exactly("group3")
      end

      context 'update visibility' do
        let(:update_params) { { visibility: 'open' } }

        it 'can make file set public' do
          patch :update, params: { id: file_set, file_set: update_params }

          expect(assigns[:file_set].read_groups).to contain_exactly('public')
        end
      end

      context "when there's an error saving" do
        let(:parent) { FactoryBot.create(:work, :public, user: user) }

        let(:file_set) do
          FactoryBot.create(:file_set, user: user).tap do |file_set|
            parent.ordered_members << file_set
            parent.save!
          end
        end

        before { allow(FileSet).to receive(:find).and_return(file_set) }

        it "draws the edit page" do
          expect(file_set).to receive(:valid?).and_return(false)
          post :update, params: { id: file_set, file_set: { keyword: [''] } }
          expect(response.code).to eq '422'
          expect(response).to render_template('edit')
          expect(response).to render_template('dashboard')
          expect(assigns[:file_set]).to eq file_set
        end
      end
    end

    describe "#edit" do
      let(:file_set) { FactoryBot.create(:file_set, read_groups: ['public']) }

      let(:file) do
        Hydra::Derivatives::IoDecorator
          .new(File.open(fixture_path + '/world.png'),
               'image/png', 'world.png')
      end

      before { Hydra::Works::UploadFileToFileSet.call(file_set, file) }

      context "someone else's files" do
        it "sets flash error" do
          get :edit, params: { id: file_set }
          expect(response.code).to eq '401'
          expect(response).to render_template('unauthorized')
          expect(response).to render_template('dashboard')
        end
      end
    end

    describe "#show" do
      let(:work) do
        FactoryBot.create(:generic_work, :public,
                          title: ['test title'],
                          user: user)
      end

      let(:file_set) do
        FactoryBot.create(:file_set, title: ['test file'], user: user).tap do |file_set|
          work.ordered_members << file_set
          work.save!
        end
      end

      before do
        work.ordered_members << file_set
        work.save!
      end

      context "without a referer" do
        let(:work) do
          FactoryBot.create(:generic_work, :public,
                            title: ['test title'],
                            user: user)
        end

        before do
          work.ordered_members << file_set
          work.save!
          file_set.save!
        end

        it "shows me the file and set breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('Works', Hyrax::Engine.routes.url_helpers.my_works_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('test title', main_app.hyrax_generic_work_path(work.id, locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('test file', main_app.hyrax_file_set_path(file_set, locale: 'en'))
          get :show, params: { id: file_set }
          expect(response).to be_successful
          expect(flash).to be_empty
          expect(assigns[:presenter]).to be_kind_of Hyrax::FileSetPresenter
          expect(assigns[:presenter].id).to eq file_set.id
          expect(assigns[:presenter].events).to be_kind_of Array
          expect(assigns[:presenter].fixity_check_status).to eq 'Fixity checks have not yet been run on this object'
        end
      end

      context "with a referer" do
        before do
          request.env['HTTP_REFERER'] = 'http://test.host/foo'
          work.ordered_members << file_set
          work.save!
          file_set.save!
        end

        it "shows me the breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with('Home', Hyrax::Engine.routes.url_helpers.root_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('Works', Hyrax::Engine.routes.url_helpers.my_works_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('test title', main_app.hyrax_generic_work_path(work.id, locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('test file', main_app.hyrax_file_set_path(file_set, locale: 'en'))
          get :show, params: { id: file_set }
          expect(response).to be_successful
        end
      end
    end

    context 'someone elses (public) files' do
      let(:creator) do
        FactoryBot.create(:user, email: 'archivist1@example.com')
      end

      let(:parent) do
        FactoryBot.create(:work, :public, user: creator, read_groups: ['public'])
      end

      let(:public_file_set) do
        FactoryBot.create(:file_set, user: creator, read_groups: ['public']).tap do |file_set|
          parent.ordered_members << file_set
          parent.save!
        end
      end

      let(:work) do
        FactoryBot.create(:generic_work, :public,
               title: ['test title'],
               user: user)
      end

      before do
        sign_in user
        work.ordered_members << public_file_set
        work.save!
        public_file_set.save!
      end

      describe '#edit' do
        it 'gives me the unauthorized page' do
          get :edit, params: { id: public_file_set }

          expect(response.code).to eq '401'
          expect(response).to render_template(:unauthorized)
          expect(response).to render_template('dashboard')
        end
      end

      describe '#show' do
        it 'allows access to the file' do
          get :show, params: { id: public_file_set }

          expect(response).to be_successful
        end
      end
    end
  end

  context 'when not signed in' do
    let(:work) { FactoryBot.create(:work, :public, user: user) }
    let(:private_file_set) { FactoryBot.create(:file_set) }
    let(:public_file_set) { FactoryBot.create(:file_set, read_groups: ['public']) }

    let(:work) do
      FactoryBot.create(:generic_work, :public,
                        title: ['test title'],
                        user: user)
    end

    before do
      work.ordered_members << private_file_set
      work.ordered_members << public_file_set
      work.save!
      public_file_set.save!
    end

    describe '#edit' do
      it 'requires login' do
        get :edit, params: { id: public_file_set }

        expect(response)
          .to fail_redirect_and_flash(main_app.new_user_session_path,
                                      'You need to sign in or sign up before continuing.')
      end
    end

    describe '#show' do
      it 'denies access to private files' do
        get :show, params: { id: private_file_set }

        expect(response)
          .to fail_redirect_and_flash(main_app.new_user_session_path(locale: 'en'),
                                      'You are not authorized to access this page.')
      end

      it 'allows access to public files' do
        expect(controller)
          .to receive(:additional_response_formats)
          .with(ActionController::MimeResponds::Collector)

        get :show, params: { id: public_file_set }

        expect(response).to be_successful
      end
    end

    describe '#show' do
      let(:parent_work_active) do
        FactoryBot
          .create(:work, :public, state: Vocab::FedoraResourceStatus.active)
      end

      let(:file_set_active) do
        FactoryBot.create(:file_set, read_groups: ['public']).tap do |file_set|
          parent_work_active.ordered_members << file_set
          parent_work_active.save!
        end
      end

      let(:parent_work_inactive) do
        FactoryBot
          .create(:work, :public, state: Vocab::FedoraResourceStatus.inactive)
      end

      let(:file_set_inactive) do
        FactoryBot.create(:file_set, read_groups: ['public']).tap do |file_set|
          parent_work_inactive.ordered_members << file_set
          parent_work_inactive.save!
        end
      end

      it "shows active parent" do
        expect(controller)
          .to receive(:additional_response_formats)
          .with(ActionController::MimeResponds::Collector)

        get :show, params: { id: file_set_active }

        expect(response).to be_successful
      end

      it "shows not currently available for inactive parent" do
        get :show, params: { id: file_set_inactive }

        expect(response).to render_template 'unavailable'
        expect(flash[:notice])
          .to eq 'The file is not currently available because its parent work ' \
                 'has not yet completed the approval process'
        expect(response.status).to eq 401
      end
    end
  end

  describe 'integration test for suppressed documents' do
    let(:work) do
      FactoryBot
        .create(:work, :public, state: Vocab::FedoraResourceStatus.inactive)
    end

    let(:file_set) do
      FactoryBot.create(:file_set, read_groups: ['public']).tap do |file_set|
        work.ordered_members << file_set
        work.save!
      end
    end

    before do
      work.ordered_members << file_set
      work.save!

      FactoryBot.create(:sipity_entity, proxy_for_global_id: work.to_global_id.to_s)
    end

    it 'renders the unavailable message because it is in workflow' do
      get :show, params: { id: file_set }

      expect(response.code).to eq '401'
      expect(response).to render_template(:unavailable)
      expect(assigns[:presenter]).to be_instance_of Hyrax::FileSetPresenter
      expect(flash[:notice]).to eq 'The file is not currently available because its parent work has not yet completed the approval process'
    end
  end
end
