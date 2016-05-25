describe CurationConcerns::FileSetsController do
  routes { Rails.application.routes }
  let(:user) { create(:user) }
  before do
    allow(controller).to receive(:has_access?).and_return(true)
    sign_in user
    allow_any_instance_of(User).to receive(:groups).and_return([])
    # prevents characterization and derivative creation
    allow(CharacterizeJob).to receive(:perform_later)
    allow(CreateDerivativesJob).to receive(:perform_later)
  end

  describe "destroy" do
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
        expect {
          delete :destroy, id: file_set
        }.to change { FileSet.exists?(file_set.id) }.from(true).to(false)
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
    end

    it "sets the breadcrumbs and versions presenter" do
      allow(controller.request).to receive(:referer).and_return('foo')
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.my.works'), Sufia::Engine.routes.url_helpers.dashboard_works_path)
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.file_set.browse_view'), Rails.application.routes.url_helpers.curation_concerns_file_set_path(file_set))
      get :edit, id: file_set

      expect(response).to be_success
      expect(assigns[:file_set]).to eq file_set
      expect(assigns[:version_list]).to be_kind_of CurationConcerns::VersionListPresenter
      expect(response).to render_template(:edit)
    end
  end

  describe "update" do
    let(:file_set) do
      FileSet.create! { |fs| fs.apply_depositor_metadata(user) }
    end

    context "when updating metadata" do
      it "spawns a content update event job" do
        expect(ContentUpdateEventJob).to receive(:perform_later).with(file_set, user)
        post :update, id: file_set,
                      file_set: { title: ['new_title'], keyword: [''],
                                  permissions_attributes: [{ type: 'person',
                                                             name: 'archivist1',
                                                             access: 'edit' }] }
      end
    end

    context "when updating the attached file" do
      it "spawns a content new version event job" do
        expect(ContentNewVersionEventJob).to receive(:perform_later).with(file_set, user)

        expect(CharacterizeJob).to receive(:perform_later).with(file_set, String)
        file = fixture_file_upload('/world.png', 'image/png')
        post :update, id: file_set, filedata: file, file_set: { keyword: [''], permissions_attributes: [{ type: 'person', name: 'archivist1', access: 'edit' }] }
        post :update, id: file_set, file_set: { files: [file], keyword: [''],
                                                permissions_attributes: [{ type: 'person', name: 'archivist1', access: 'edit' }] }
      end
    end

    context "with two existing versions from different users" do
      let(:file1)       { "world.png" }
      let(:file2)       { "image.jpg" }
      let(:second_user) { create(:user) }
      let(:version1)    { "version1" }
      let(:actor1)      { CurationConcerns::Actors::FileSetActor.new(file_set, user) }
      let(:actor2)      { CurationConcerns::Actors::FileSetActor.new(file_set, second_user) }

      before do
        actor1.create_content(fixture_file_upload(file1))
        actor2.create_content(fixture_file_upload(file2))
      end

      describe "restoring a previous version" do
        context "as the first user" do
          before do
            sign_in user
            post :update, id: file_set, revision: version1
          end

          let(:restored_content) { file_set.reload.original_file }
          let(:versions)         { restored_content.versions }
          let(:latest_version)   { CurationConcerns::VersioningService.latest_version_of(restored_content) }

          it "restores the first versions's content and metadata" do
            # expect(restored_content.mime_type).to eq "image/png"
            expect(restored_content.original_name).to eq file1
            expect(versions.all.count).to eq 3
            expect(versions.last.label).to eq latest_version.label
            expect(VersionCommitter.where(version_id: versions.last.uri).pluck(:committer_login)).to eq [user.user_key]
          end
        end

        context "as a user without edit access" do
          before do
            sign_in second_user
          end

          it "is unauthorized" do
            post :update, id: file_set, revision: version1
            expect(response.code).to eq '401'
            expect(response).to render_template 'unauthorized'
          end
        end
      end
    end

    it "adds new groups and users" do
      post :update, id: file_set,
                    file_set: { keyword: [''],
                                permissions_attributes: [
                                  { type: 'person', name: 'user1', access: 'edit' },
                                  { type: 'group', name: 'group1', access: 'read' }
                                ] }

      expect(assigns[:file_set].read_groups).to eq ["group1"]
      expect(assigns[:file_set].edit_users).to include("user1", user.user_key)
    end

    it "updates existing groups and users" do
      file_set.edit_groups = ['group3']
      file_set.save
      post :update, id: file_set,
                    file_set: { keyword: [''],
                                permissions_attributes: [
                                  { id: file_set.permissions.last.id, type: 'group', name: 'group3', access: 'read' }
                                ] }

      expect(assigns[:file_set].read_groups).to eq(["group3"])
    end

    it "spawns a virus check" do
      file = fixture_file_upload('/world.png', 'image/png')

      expect(ContentNewVersionEventJob).to receive(:perform_later).with(file_set, user)
      expect(ClamAV.instance).to receive(:scanfile).and_return(0)
      expect(CharacterizeJob).to receive(:perform_later).with(file_set, String)
      post :update, id: file_set.id, 'Filename' => 'The world',
                    file_set: { files: [file], keyword: [''],
                                permissions_attributes: [{ type: 'user', name: 'archivist1', access: 'edit' }] }
    end

    context "when there's an error saving" do
      let!(:file_set) do
        FileSet.create do |fs|
          fs.apply_depositor_metadata(user)
        end
      end
      it "draws the edit page" do
        expect_any_instance_of(FileSet).to receive(:valid?).and_return(false)
        post :update, id: file_set, file_set: { keyword: [''] }
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
        get :edit, id: file_set
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
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
        get :show, id: file_set
        expect(response).to be_successful
        expect(flash).to be_empty
        expect(assigns[:presenter]).to be_kind_of Sufia::FileSetPresenter
        expect(assigns[:presenter].id).to eq file_set.id
        expect(assigns[:presenter].events).to be_kind_of Array
        expect(assigns[:presenter].audit_status).to eq 'Audits have not yet been run on this file.'
      end
    end

    context "with a referer" do
      let(:work) do
        create(:generic_work,
               title: ['test title'],
               user: user,
               visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      end

      before do
        allow(controller.request).to receive(:referer).and_return('foo')
        work.ordered_members << file_set
        work.save!
        file_set.save!
      end

      it "shows me the breadcrumbs" do
        expect(controller).to receive(:add_breadcrumb).with('My Dashboard', Sufia::Engine.routes.url_helpers.dashboard_index_path)
        expect(controller).to receive(:add_breadcrumb).with('My Works', Sufia::Engine.routes.url_helpers.dashboard_works_path)
        expect(controller).to receive(:add_breadcrumb).with('test title', Sufia::Engine.routes.url_helpers.curation_concerns_generic_work_path(work.id))
        expect(controller).to receive(:add_breadcrumb).with('test file', main_app.curation_concerns_file_set_path(file_set))
        get :show, id: file_set
        expect(response).to be_successful
      end
    end
  end
end
