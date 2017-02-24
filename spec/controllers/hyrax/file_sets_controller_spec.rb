describe Hyrax::FileSetsController do
  routes { Rails.application.routes }
  let(:user) { create(:user) }

  context "when signed in" do
    before do
      sign_in user
      # allow_any_instance_of(User).to receive(:groups).and_return([])
      # prevents characterization and derivative creation
      allow(CharacterizeJob).to receive(:perform_later)
      allow(CreateDerivativesJob).to receive(:perform_later)
    end

    describe '#create' do
      let(:parent) do
        create(:generic_work, :public,
               edit_users: [user.user_key])
      end
      let(:file) { fixture_file_upload('image.png', 'image/png') }

      context 'on the happy path' do
        let(:expected_params) do
          { files: [file],
            title: ['test title'],
            visibility: 'restricted' }
        end
        let(:actor) { controller.send(:actor) }

        it 'calls the actor to create metadata and content' do
          expect(actor).to receive(:create_metadata).with(ActionController::Parameters) do |ac_params|
            expect(ac_params['files'].map(&:class)).to eq [ActionDispatch::Http::UploadedFile]
            expect(ac_params['title']).to eq expected_params[:title]
            expect(ac_params['visibility']).to eq expected_params[:visibility]
          end
          expect(actor).to receive(:attach_file_to_work).with(parent).and_return(true)
          expect(actor).to receive(:create_content).with(ActionDispatch::Http::UploadedFile).and_return(true)

          post :create, xhr: true, params: { parent_id: parent,
                                             file_set: {
                                               files: [file],
                                               title: ['test title'],
                                               visibility: 'restricted'
                                             } }
          expect(response).to be_success
          expect(flash[:error]).to be_nil
        end
      end

      context "on something that isn't a file" do
        # Note: This is a duplicate of coverage in file_sets_controller_json_spec.rb
        it 'renders error' do
          post :create, xhr: true, params: { parent_id: parent,
                                             file_set: { files: ['hello'] },
                                             permission: { group: { 'public' => 'read' } },
                                             terms_of_service: '1' }
          expect(response.status).to eq 400
          msg = JSON.parse(response.body)['message']
          expect(msg).to match(/no file for upload/i)
        end
      end

      subject { create(:file_set) }
      let(:file_path) { fixture_path + '/small_file.txt' }

      context 'when the file has a virus' do
        before do
          allow(subject).to receive(:warn) # suppress virus warnings
          allow(Hydra::Works::VirusCheckerService).to receive(:file_has_virus?) { true }
          of = subject.build_original_file
          of.content = File.open(file_path)
        end
        it 'populates the errors hash during validation' do
          expect(subject).not_to be_valid
          expect(subject.errors.messages[:base].first).to eq "Failed to verify uploaded file is not a virus"
        end
      end

      context 'when solr is down' do
        before do
          allow(controller.send(:actor)).to receive(:create_metadata)
          allow(controller.send(:actor)).to receive(:attach_file_to_work)
          allow(controller.send(:actor)).to receive(:create_content).and_raise(RSolr::Error::Http.new({}, {}))
        end

        it 'errors out of create after on continuous rsolr error' do
          post :create, xhr: true, params: {
            parent_id: parent,
            file_set: { files: [file] },
            permission: { group: { 'public' => 'read' } },
            terms_of_service: '1'
          }
          expect(response.body).to include('Error occurred while creating a FileSet.')
        end
      end

      context 'when the file is not created' do
        before do
          allow(controller.send(:actor)).to receive(:create_metadata)
          allow(controller.send(:actor)).to receive(:attach_file_to_work)
          allow(controller.send(:actor)).to receive(:create_content).and_return(false)
        end

        it 'errors out of create after on continuous rsolr error' do
          post :create, xhr: true, params: {
            parent_id: parent,
            file_set: { files: [file] },
            permission: { group: { 'public' => 'read' } },
            terms_of_service: '1'
          }
          expect(response.body).to include('Error creating file image.png')
        end
      end
    end

    describe "#destroy" do
      context "file_set with a parent" do
        let(:file_set) do
          FileSet.create do |fs|
            fs.apply_depositor_metadata(user)
          end
        end
        let(:work) do
          GenericWork.create!(title: ['test title']) do |w|
            w.apply_depositor_metadata(user)
          end
        end

        let(:delete_message) { double('delete message') }
        before do
          work.ordered_members << file_set
          work.save!
        end

        it "deletes the file" do
          expect(ContentDeleteEventJob).to receive(:perform_later).with(file_set.id, user)
          expect do
            delete :destroy, params: { id: file_set }
          end.to change { FileSet.exists?(file_set.id) }.from(true).to(false)
          expect(response).to redirect_to main_app.hyrax_generic_work_path(work, locale: 'en')
        end
      end
    end

    describe "#edit" do
      let(:file_set) do
        FileSet.create do |fs|
          fs.apply_depositor_metadata(user)
        end
      end

      before do
        binary = StringIO.new("hey")
        Hydra::Works::AddFileToFileSet.call(file_set, binary, :original_file, versioning: true)
        request.env['HTTP_REFERER'] = 'http://test.host/foo'
      end

      it "sets the breadcrumbs and versions presenter" do
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.title'), Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.my.works'), Hyrax::Engine.routes.url_helpers.my_works_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.file_set.browse_view'), Rails.application.routes.url_helpers.hyrax_file_set_path(file_set, locale: 'en'))
        get :edit, params: { id: file_set }

        expect(response).to be_success
        expect(assigns[:file_set]).to eq file_set
        expect(assigns[:version_list]).to be_kind_of Hyrax::VersionListPresenter
        expect(response).to render_template(:edit)
      end
    end

    describe "#update" do
      let(:file_set) do
        FileSet.create! { |fs| fs.apply_depositor_metadata(user) }
      end

      context "when updating metadata" do
        it "spawns a content update event job" do
          expect(ContentUpdateEventJob).to receive(:perform_later).with(file_set, user)
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
          expect(response).to redirect_to main_app.hyrax_file_set_path(file_set, locale: 'en')
        end
      end

      context "when updating the attached file" do
        let(:actor) { double }
        before do
          allow(Hyrax::Actors::FileActor).to receive(:new).and_return(actor)
        end
        let(:expected_file_type) do
          ActionDispatch::Http::UploadedFile
        end

        it "spawns a content new version event job" do
          expect(ContentNewVersionEventJob).to receive(:perform_later).with(file_set, user)

          expect(actor).to receive(:ingest_file).with(expected_file_type)
          file = fixture_file_upload('/world.png', 'image/png')
          post :update, params: { id: file_set, filedata: file, file_set: { keyword: [''], permissions_attributes: [{ type: 'person', name: 'archivist1', access: 'edit' }] } }
          post :update, params: { id: file_set, file_set: { files: [file], keyword: [''], permissions_attributes: [{ type: 'person', name: 'archivist1', access: 'edit' }] } }
        end
      end

      context "with two existing versions from different users" do
        let(:file1)       { "world.png" }
        let(:file2)       { "image.jpg" }
        let(:second_user) { create(:user) }
        let(:version1)    { "version1" }
        let(:actor1)      { Hyrax::Actors::FileSetActor.new(file_set, user) }
        let(:actor2)      { Hyrax::Actors::FileSetActor.new(file_set, second_user) }

        before do
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
              expect(restored_content.original_name).to eq file1
              expect(versions.all.count).to eq 3
              expect(versions.last.label).to eq latest_version.label
              expect(Hyrax::VersionCommitter.where(version_id: versions.last.uri).pluck(:committer_login)).to eq [user.user_key]
            end
          end

          context "as a user without edit access" do
            before do
              sign_in second_user
            end

            it "is unauthorized" do
              post :update, params: { id: file_set, revision: version1 }
              expect(response.code).to eq '401'
              expect(response).to render_template 'unauthorized'
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

        expect(assigns[:file_set].read_groups).to eq ["group1"]
        expect(assigns[:file_set].edit_users).to include("user1", user.user_key)
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

        expect(assigns[:file_set].read_groups).to eq(["group3"])
      end

      context "when there's an error saving" do
        let(:file_set) do
          FileSet.create do |fs|
            fs.apply_depositor_metadata(user)
          end
        end
        before do
          allow(FileSet).to receive(:find).and_return(file_set)
        end
        it "draws the edit page" do
          expect(file_set).to receive(:valid?).and_return(false)
          post :update, params: { id: file_set, file_set: { keyword: [''] } }
          expect(response.code).to eq '422'
          expect(response).to render_template('edit')
          expect(assigns[:file_set]).to eq file_set
        end
      end
    end

    describe "#edit" do
      let(:file_set) do
        FileSet.create(read_groups: ['public']) do |f|
          f.apply_depositor_metadata('archivist1@example.com')
        end
      end

      let(:file) do
        Hydra::Derivatives::IoDecorator.new(File.open(fixture_path + '/world.png'),
                                            'image/png', 'world.png')
      end

      before do
        Hydra::Works::UploadFileToFileSet.call(file_set, file)
      end

      context "someone else's files" do
        it "sets flash error" do
          get :edit, params: { id: file_set }
          expect(response.code).to eq '401'
          expect(response).to render_template('unauthorized')
        end
      end
    end

    describe "#show" do
      let(:file_set) do
        create(:file_set, title: ['test file'], user: user)
      end
      context "without a referer" do
        it "shows me the file and set breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.title'), Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
          get :show, params: { id: file_set }
          expect(response).to be_successful
          expect(flash).to be_empty
          expect(assigns[:presenter]).to be_kind_of Hyrax::FileSetPresenter
          expect(assigns[:presenter].id).to eq file_set.id
          expect(assigns[:presenter].events).to be_kind_of Array
          expect(assigns[:presenter].audit_status).to eq 'Audits have not yet been run on this file.'
        end
      end

      context "with a referer" do
        let(:work) do
          create(:generic_work, :public,
                 title: ['test title'],
                 user: user)
        end

        before do
          request.env['HTTP_REFERER'] = 'http://test.host/foo'
          work.ordered_members << file_set
          work.save!
          file_set.save!
        end

        it "shows me the breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with('My Dashboard', Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('Your Works', Hyrax::Engine.routes.url_helpers.my_works_path(locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('test title', main_app.hyrax_generic_work_path(work.id, locale: 'en'))
          expect(controller).to receive(:add_breadcrumb).with('test file', main_app.hyrax_file_set_path(file_set, locale: 'en'))
          get :show, params: { id: file_set }
          expect(response).to be_successful
        end
      end
    end

    context 'someone elses (public) files' do
      let(:creator) { create(:user, email: 'archivist1@example.com') }
      let(:public_file_set) { create(:file_set, user: creator, read_groups: ['public']) }
      before { sign_in user }

      describe '#edit' do
        it 'gives me the unauthorized page' do
          get :edit, params: { id: public_file_set }
          expect(response.code).to eq '401'
          expect(response).to render_template(:unauthorized)
        end
      end

      describe '#show' do
        it 'allows access to the file' do
          get :show, params: { id: public_file_set }
          expect(response).to be_success
        end
      end
    end
  end

  context 'when not signed in' do
    let(:private_file_set) { create(:file_set) }
    let(:public_file_set) { create(:file_set, read_groups: ['public']) }

    describe '#edit' do
      it 'requires login' do
        get :edit, params: { id: public_file_set }
        expect(response).to fail_redirect_and_flash(main_app.new_user_session_path, 'You need to sign in or sign up before continuing.')
      end
    end

    describe '#show' do
      it 'denies access to private files' do
        get :show, params: { id: private_file_set }
        expect(response).to fail_redirect_and_flash(main_app.new_user_session_path(locale: 'en'), 'You are not authorized to access this page.')
      end

      it 'allows access to public files' do
        expect(controller).to receive(:additional_response_formats).with(ActionController::MimeResponds::Collector)
        get :show, params: { id: public_file_set }
        expect(response).to be_success
      end
    end

    describe '#new' do
      let(:parent) do
        create(:generic_work, :public)
      end
      it 'does not let the user submit' do
        get :new, params: { parent_id: parent }
        expect(response).to fail_redirect_and_flash(main_app.new_user_session_path, 'You need to sign in or sign up before continuing.')
      end
    end
  end

  context 'finds parents' do
    let(:parent) do
      create(:generic_work, :public,
             edit_users: [user.user_key])
    end

    let(:file_set) do
      file_set = FileSet.create! do |gf|
        gf.apply_depositor_metadata(user)
      end
      parent.ordered_members << file_set
      parent.save
      file_set
    end

    before do
      allow(controller).to receive(:curation_concern).and_return(file_set)
    end

    it 'finds a parent' do
      expect(controller.parent).to eq(parent)
    end

    it 'finds a parent id' do
      expect(controller.parent_id).to eq(parent.id)
    end
  end
end
