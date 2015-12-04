require 'spec_helper'

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

  describe "#create" do
    let(:file) { fixture_file_upload('files/image.png', 'image/png') }
    let(:parent) do
      create(:generic_work,
             edit_users: [user.user_key],
             visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
    end

    context "when uploading a file" do
      let(:file_set) { build(:file_set) }
      let(:reloaded_file_set) { file_set.reload }
      let(:upload_set) { UploadSet.create! }
      let(:upload_set_id) { upload_set.id }
      let(:file) { fixture_file_upload('/world.png', 'image/png') }

      before do
        allow(FileSet).to receive(:new).and_return(file_set)
      end

      context "when the file submitted isn't a file" do
        it 'renders error' do
          xhr :post, :create, parent_id: parent,
                              file_set: { files: ['hello'],
                                          permission: { group: { 'public' => 'read' } } },
                              terms_of_service: '1'
          expect(response.status).to eq 400
          msg = JSON.parse(response.body)['message']
          expect(msg).to match(/no file for upload/i)
        end
      end

      context "when everything is perfect" do
        let(:date_today) { DateTime.now }

        before do
          allow(DateTime).to receive(:now).and_return(date_today)
        end

        context "when a work id is passed in" do
          it 'calls the actor to create metadata and content' do
            expect(controller.send(:actor)).to receive(:create_metadata)
              .with(nil, parent, files: [file],
                                 title: ['test title'],
                                 visibility: 'restricted')
            expect(controller.send(:actor)).to receive(:create_content).with(file).and_return(true)
            xhr :post, :create, parent_id: parent,
                                terms_of_service: '1',
                                file_set: { files: [file],
                                            title: ['test title'],
                                            visibility: 'restricted' }
            expect(response).to be_success
            expect(flash[:error]).to be_nil
          end

          context "and an UploadSet is passed in" do
            it "calls the actor with the upload_set" do
              expect(controller.send(:actor)).to receive(:create_metadata).with(upload_set_id, parent, Hash)
              expect(controller.send(:actor)).to receive(:create_content)
              xhr :post, :create, parent_id: parent,
                                  terms_of_service: '1',
                                  upload_set_id: upload_set_id,
                                  file_set: { files: [file],
                                              Filename: 'The world 1',
                                              on_behalf_of: 'carolyn',
                                              terms_of_service: '1' }
              expect(response).to be_success
            end
          end
        end

        context "when a work id is not passed" do
          it "creates the FileSet" do
            skip "Creating a FileSet without a parent work is not yet supported"
            xhr :post, :create, file_set: { files: [file], Filename: 'The world' },
                                upload_set_id: upload_set_id,
                                terms_of_service: '1'
            expect(response).to be_success
            expect(reloaded_file_set.generic_works).not_to be_empty
          end
        end
      end

      context "when the file has a virus" do
        it "displays a flash error" do
          pending "There's no way to do this because the scan happens in a background job"
          expect(ClamAV.instance).to receive(:scanfile).and_return("EL CRAPO VIRUS")
          xhr :post, :create, parent_id: parent,
                              upload_set_id: "sample_upload_set_id",
                              file_set: { files: [file], Filename: "The world",
                                          permission: { "group" => { "public" => "read" } } },
                              terms_of_service: '1'
          expect(flash[:error]).not_to be_blank
          expect(flash[:error]).to include('A virus was found')
        end
      end

      context "when solr continuously has errors" do
        before do
          allow(controller.send(:actor)).to receive(:create_metadata)
          allow(controller.send(:actor)).to receive(:create_content).with(file).and_raise(RSolr::Error::Http.new({}, {}))
        end

        it "errors out of create and save" do
          xhr :post, :create, parent_id: parent,
                              upload_set_id: "sample_upload_set_id",
                              file_set: { files: [file], Filename: "The world",
                                          permission: { "group" => { "public" => "read" } } },
                              terms_of_service: "1"
          expect(response.body).to include("Error occurred while creating a FileSet.")
        end
      end
    end

    context "with browse-everything" do
      let(:batch) { UploadSet.create }
      let(:upload_set_id) { batch.id }

      before do
        @json_from_browse_everything = { "0" => { "url" => "https://dl.dropbox.com/fake/blah-blah.filepicker-demo.txt.txt", "expires" => "2014-03-31T20:37:36.214Z", "file_name" => "filepicker-demo.txt.txt" }, "1" => { "url" => "https://dl.dropbox.com/fake/blah-blah.Getting%20Started.pdf", "expires" => "2014-03-31T20:37:36.731Z", "file_name" => "Getting+Started.pdf" } }
      end
      context "when no work_id is passed" do
        it "ingests files from provide URLs" do
          skip "Creating a FileSet without a parent work is not yet supported"
          expect(ImportUrlJob).to receive(:perform_later).twice
          expect { post :create, selected_files: @json_from_browse_everything,
                                 upload_set_id: upload_set_id,
                                 file_set: {}
          }.to change(FileSet, :count).by(2)
          created_files = FileSet.all
          ["https://dl.dropbox.com/fake/blah-blah.Getting%20Started.pdf", "https://dl.dropbox.com/fake/blah-blah.filepicker-demo.txt.txt"].each do |url|
            expect(created_files.map(&:import_url)).to include(url)
          end
          ["filepicker-demo.txt.txt", "Getting+Started.pdf"].each do |filename|
            expect(created_files.map(&:label)).to include(filename)
          end
        end
      end

      context "when a work id is passed" do
        let(:work) do
          GenericWork.create!(title: ['test title']) do |w|
            w.apply_depositor_metadata(user)
          end
        end
        it "records the work" do
          expect(ImportUrlJob).to receive(:perform_later).twice
          expect {
            post :create, selected_files: @json_from_browse_everything,
                          parent_id: work.id,
                          file_set: {},
                          upload_set_id: upload_set_id
          }.to change(FileSet, :count).by(2)
          created_files = FileSet.all
          created_files.each { |f| expect(f.generic_works).to include work }
        end
      end

      context "when a work id is not passed" do
        it "creates the work" do
          skip "Creating a FileSet without a parent work is not yet supported"
          expect(ImportUrlJob).to receive(:new).twice
          expect {
            post :create, selected_files: @json_from_browse_everything,
                          file_set: {},
                          upload_set_id: upload_set_id
          }.to change(FileSet, :count).by(2)
          created_files = FileSet.all
          expect(created_files[0].generic_works.first).not_to eq created_files[1].generic_works.first
        end
      end
    end

    context "with local_file" do
      let(:file_set_url) { "http://example.com" }
      let(:file_set_upload_directory) { 'spec/mock_upload_directory' }
      let(:batch) { UploadSet.create }
      let(:upload_set_id) { batch.id }

      context "when User model defines a directory path" do
        before do
          Sufia.config.enable_local_ingest = true
          FileUtils.mkdir_p([File.join(file_set_upload_directory, "import/files"), File.join(file_set_upload_directory, "import/metadata")])
          FileUtils.copy(File.expand_path('../../fixtures/world.png', __FILE__), file_set_upload_directory)
          FileUtils.copy(File.expand_path('../../fixtures/image.jpg', __FILE__), file_set_upload_directory)
          FileUtils.copy(File.expand_path('../../fixtures/dublin_core_rdf_descMetadata.nt', __FILE__), File.join(file_set_upload_directory, "import/metadata"))
          FileUtils.copy(File.expand_path('../../fixtures/icons.zip', __FILE__), File.join(file_set_upload_directory, "import/files"))
          FileUtils.copy(File.expand_path('../../fixtures/Example.ogg', __FILE__), File.join(file_set_upload_directory, "import/files"))

          allow_any_instance_of(User).to receive(:directory).and_return(file_set_upload_directory)
        end

        after do
          Sufia.config.enable_local_ingest = false
          FileUtils.remove_dir(File.join(file_set_upload_directory, "import/files"), true)
          FileUtils.remove_dir(File.join(file_set_upload_directory, "import/metadata"), true)
        end

        context "without a parent work id" do
          it "ingests files from the filesystem" do
            skip "Creating a FileSet without a parent work is not yet supported (no route)"

            expect_any_instance_of(Sufia::IngestLocalFileService)
              .to receive(:ingest_local_file)
              .with(["world.png", "image.jpg"], nil, upload_set_id)

            post :create, file_set: { local_file: ["world.png", "image.jpg"] }, upload_set_id: upload_set_id
            expect(response).to redirect_to Sufia::Engine.routes.url_helpers.batch_edit_path(upload_set_id)
          end

          it "ingests redirect to another location" do
            skip "Creating a FileSet without a parent work is not yet supported (no route)"

            expect_any_instance_of(Sufia::IngestLocalFileService)
              .to receive(:ingest_local_file)
              .with(["world.png"], nil, upload_set_id)

            expect(described_class).to receive(:upload_complete_path).and_return(file_set_url)
            post :create, file_set: { local_file: ["world.png"] }, upload_set_id: upload_set_id
            expect(response).to redirect_to file_set_url
          end

          it "ingests directories from the filesystem" do
            skip "Creating a FileSet without a parent work is not yet supported (no route)"

            expect_any_instance_of(Sufia::IngestLocalFileService)
              .to receive(:ingest_local_file)
              .with(["world.png", "import"], nil, upload_set_id)

            post :create, file_set: { local_file: ["world.png", "import"] }, upload_set_id: upload_set_id
          end
        end

        context "when a work id is passed" do
          let(:work) do
            GenericWork.create!(title: ['test title']) do |w|
              w.apply_depositor_metadata(user)
            end
          end

          before do
            expect_any_instance_of(Sufia::IngestLocalFileService)
              .to receive(:ingest_local_file)
              .with(["world.png", "image.jpg"], work.id, upload_set_id)
          end

          it "records the work" do
            post :create, parent_id: work.id, upload_set_id: upload_set_id, file_set: { local_file: ["world.png", "image.jpg"] }
          end
        end
      end

      context "when User model does not define directory path" do
        context "without a parent work id" do
          it "returns an error message and redirects to file upload page" do
            skip "Creating a FileSet without a parent work is not yet supported"
            expect {
              post :create, file_set: { local_file: ["world.png", "image.jpg"] },
                            upload_set_id: upload_set_id
            }.not_to change(FileSet, :count)
            expect(response).to render_template :new
            expect(flash[:alert]).to eq 'Your account is not configured for importing files from a user-directory on the server.'
          end
        end
      end
    end
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
        expect(ContentDeleteEventJob).to receive(:perform_later).with(file_set.id, user.user_key)
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
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.my.files'), Sufia::Engine.routes.url_helpers.dashboard_files_path)
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
        expect(ContentUpdateEventJob).to receive(:perform_later).with(file_set.id, user.user_key)
        post :update, id: file_set,
                      file_set: { title: ['new_title'], tag: [''],
                                  permissions_attributes: [{ type: 'person',
                                                             name: 'archivist1',
                                                             access: 'edit' }] }
      end
    end

    context "when updating the attached file" do
      it "spawns a content new version event job" do
        expect(ContentNewVersionEventJob).to receive(:perform_later).with(file_set.id, user.user_key)

        expect(CharacterizeJob).to receive(:perform_later).with(file_set.id, String)
        file = fixture_file_upload('/world.png', 'image/png')
        post :update, id: file_set, filedata: file, file_set: { tag: [''], permissions_attributes: [{ type: 'person', name: 'archivist1', access: 'edit' }] }
        post :update, id: file_set, file_set: { files: [file], tag: [''],
                                                permissions_attributes: [{ type: 'person', name: 'archivist1', access: 'edit' }] }
      end
    end

    context "with two existing versions from different users" do
      let(:file1)       { "world.png" }
      let(:file2)       { "image.jpg" }
      let(:second_user) { create(:user) }
      let(:version1)    { "version1" }
      let(:actor1)      { CurationConcerns::FileSetActor.new(file_set, user) }
      let(:actor2)      { CurationConcerns::FileSetActor.new(file_set, second_user) }

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
                    file_set: { tag: [''],
                                permissions_attributes: [
                                  { type: 'person', name: 'user1', access: 'edit' },
                                  { type: 'group', name: 'group1', access: 'read' }
                                ]
                      }

      expect(assigns[:file_set].read_groups).to eq ["group1"]
      expect(assigns[:file_set].edit_users).to include("user1", user.user_key)
    end

    it "updates existing groups and users" do
      file_set.edit_groups = ['group3']
      file_set.save
      post :update, id: file_set,
                    file_set: { tag: [''],
                                permissions_attributes: [
                                  { id: file_set.permissions.last.id, type: 'group', name: 'group3', access: 'read' }
                                ]
                      }

      expect(assigns[:file_set].read_groups).to eq(["group3"])
    end

    it "spawns a virus check" do
      file = fixture_file_upload('/world.png', 'image/png')

      expect(ContentNewVersionEventJob).to receive(:perform_later).with(file_set.id, user.user_key)
      expect(ClamAV.instance).to receive(:scanfile).and_return(0)
      expect(CharacterizeJob).to receive(:perform_later).with(file_set.id, String)
      post :update, id: file_set.id, 'Filename' => 'The world',
                    file_set: { files: [file], tag: [''],
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
        post :update, id: file_set, file_set: { tag: [''] }
        expect(response.code).to eq '422'
        expect(response).to render_template('edit')
        expect(assigns[:file_set]).to eq file_set
      end
    end
  end

  describe "someone else's files" do
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

    describe "edit" do
      it "sets flash error" do
        get :edit, id: file_set
        expect(response.code).to eq '401'
        expect(response).to render_template('unauthorized')
      end
    end

    describe "#show" do
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

      it 'renders an endnote file' do
        get :show, id: file_set, format: 'endnote'
        expect(response).to be_successful
      end
    end
  end

  describe "flash" do
    it "doesn't let the user submit if they logout" do
      sign_out user
      get :new, parent_id: 'foo'
      expect(response).not_to be_success
      expect(flash[:alert]).to include("You need to sign in or sign up before continuing")
    end

    it "filters flash if they signin" do
      sign_in user
      get :new, parent_id: 'foo'
      expect(flash[:alert]).to be_nil
    end
  end

  describe "notifications" do
    before do
      User.audituser.send_message(user, "Test message", "Test subject")
    end

    it "displays notifications" do
      get :new, parent_id: '123'
      expect(assigns[:notify_number]).to eq 1
      expect(user.mailbox.inbox[0].messages[0].subject).to eq "Test subject"
    end
  end

  describe "GET /new" do
    it "sets the form" do
      get :new, parent_id: '123'
      expect(assigns[:upload_set_id]).to be_present
      expect(response).to render_template('curation_concerns/file_sets/new')
    end
  end
end
