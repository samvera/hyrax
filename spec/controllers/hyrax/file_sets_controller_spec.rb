RSpec.describe Hyrax::FileSetsController do
  routes { Rails.application.routes }
  let(:user) { create(:user) }
  let(:actor) { controller.send(:actor) }
  let(:persister) { Valkyrie::MetadataAdapter.find(:indexing_persister).persister }

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
        create_for_repository(:work, :public, edit_users: [user.user_key])
      end
      let(:file) { fixture_file_upload('image.png', 'image/png') }
      let(:file_path) { fixture_path + '/small_file.txt' }

      context 'on the happy path' do
        let(:expected_params) do
          { files: [file],
            title: ['test title'],
            visibility: 'restricted' }
        end

        it 'calls the actor to create metadata and content' do
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
          expect(msg).to match(/No file uploaded/i)
        end
      end
    end

    describe "#destroy" do
      context "file_set with a parent" do
        let(:file_set) do
          create_for_repository(:file_set, user: user)
        end
        let!(:work) do
          create_for_repository(:work, title: ['test title'], user: user, member_ids: [file_set.id])
        end

        let(:delete_message) { double('delete message') }

        it "deletes the file" do
          expect(ContentDeleteEventJob).to receive(:perform_later).with(file_set.id.to_s, user)
          expect do
            delete :destroy, params: { id: file_set }
          end.to change { Hyrax::Queries.exists?(file_set.id) }.from(true).to(false)
          expect(response).to redirect_to main_app.hyrax_generic_work_path(work, locale: 'en')
        end
      end
    end

    describe "#edit" do
      let(:file) { fixture_file_upload('/world.png', 'image/png') }
      let(:file_set) do
        create_for_repository(:file_set, user: user, content: file)
      end

      before do
        request.env['HTTP_REFERER'] = 'http://test.host/foo'
      end

      it "sets the breadcrumbs and versions presenter" do
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.title'), Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.my.works'), Hyrax::Engine.routes.url_helpers.my_works_path(locale: 'en'))
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.file_set.browse_view'), Rails.application.routes.url_helpers.hyrax_file_set_path(file_set, locale: 'en'))
        get :edit, params: { id: file_set }

        expect(response).to be_success
        expect(assigns[:change_set]).to be_kind_of Hyrax::FileSetChangeSet
        expect(response).to render_template(:edit)
      end
    end

    describe "#update" do
      let(:file_set) do
        create_for_repository(:file_set, user: user)
      end

      context "when updating metadata" do
        it "spawns a content update event job" do
          expect(ContentUpdateEventJob).to receive(:perform_later).with(::FileSet, user)
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
        it "spawns a ContentNewVersionEventJob" do
          expect(ContentNewVersionEventJob).to receive(:perform_later).with(::FileSet, user)
          file = fixture_file_upload('/world.png', 'image/png')
          post :update, params: { id: file_set, file_set: { files: [file] } }
        end
      end

      context "with two existing versions from different users" do
        let(:file1)       { "world.png" }
        let(:file2)       { "image.jpg" }
        let(:second_user) { create(:user) }
        let(:version1)    { "version1" }

        # let(:actor1)      { Hyrax::Actors::FileSetActor.new(file_set, user) }
        # let(:actor2)      { Hyrax::Actors::FileSetActor.new(file_set, second_user) }

        before do
          # TODO: how do we make versions?
          # actor1.create_content(fixture_file_upload(file1))
          # actor2.create_content(fixture_file_upload(file2))
        end

        describe "restoring a previous version" do
          context "as the first user" do
            before do
              sign_in user
              post :update, params: { id: file_set, revision: version1 }
            end

            let(:restored_content) { file_set.reload.original_file }
            let(:versions)         { restored_content.versions }

            # let(:latest_version)   { Hyrax::VersioningService.latest_version_of(restored_content) }

            it "restores the first versions's content and metadata" do
              # expect(restored_content.mime_type).to eq "image/png"
              expect(restored_content).to be_a(Hydra::PCDM::File)
              expect(restored_content.original_name).to eq file1
              expect(versions.all.count).to eq 3
              # expect(versions.last.label).to eq latest_version.label
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

        expect(assigns[:resource].read_groups).to eq ["group1"]
        expect(assigns[:resource].edit_users).to include("user1", user.user_key)
      end

      it "updates existing groups and users" do
        file_set.edit_groups = ['group3']
        persister.save(resource: file_set)

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
          create_for_repository(:file_set, user: user)
        end

        it "draws the edit page" do
          allow_any_instance_of(Hyrax::FileSetChangeSet).to receive(:validate).and_return(false)
          post :update, params: { id: file_set, file_set: { keyword: [''] } }
          expect(response.code).to eq '422'
          expect(response).to render_template('edit')
          expect(assigns[:change_set]).to be_kind_of Hyrax::FileSetChangeSet
        end
      end
    end

    describe "#edit" do
      let(:file_set) do
        create_for_repository(:file_set, read_groups: ['public'])
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
        create_for_repository(:file_set, title: ['test file'], user: user)
      end

      context "without a referer" do
        it "shows me the file and set breadcrumbs" do
          expect(controller).to receive(:add_breadcrumb).with(I18n.t('hyrax.dashboard.title'), Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en'))
          get :show, params: { id: file_set }
          expect(response).to be_successful
          expect(flash).to be_empty
          expect(assigns[:presenter]).to be_kind_of Hyrax::FileSetPresenter
          expect(assigns[:presenter].id).to eq file_set.id.to_s
          expect(assigns[:presenter].events).to be_kind_of Array
          expect(assigns[:presenter].fixity_check_status).to eq 'Fixity checks have not yet been run on this object'
        end
      end

      context "with a referer" do
        let(:work) do
          create_for_repository(:work, :public,
                                title: ['test title'],
                                user: user)
        end

        before do
          request.env['HTTP_REFERER'] = 'http://test.host/foo'
          work.member_ids += [file_set.id]
          persister.save(resource: work)
          persister.save(resource: file_set) # Is this necessary?
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
      let(:public_file_set) { create_for_repository(:file_set, user: creator, read_groups: ['public']) }

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
    let(:private_file_set) { create_for_repository(:file_set) }
    let(:public_file_set) { create_for_repository(:file_set, read_groups: ['public']) }

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
        create_for_repository(:work, :public)
      end

      it 'does not let the user submit' do
        get :new, params: { parent_id: parent }
        expect(response).to fail_redirect_and_flash(main_app.new_user_session_path, 'You need to sign in or sign up before continuing.')
      end
    end
  end

  context 'finds parents' do
    let(:parent) do
      create_for_repository(:work, :public, edit_users: [user.user_key])
    end

    let(:file_set) do
      file_set = create_for_repository(:file_set, user: user)
      parent.member_ids += [file_set.id]
      persister.save(resource: parent)
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
