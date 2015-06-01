require 'spec_helper'

describe GenericFilesController do
  let(:user) { FactoryGirl.find_or_create(:jill) }
  before do
    allow(controller).to receive(:has_access?).and_return(true)
    sign_in user
    allow_any_instance_of(User).to receive(:groups).and_return([])
    allow(controller).to receive(:clear_session_user) ## Don't clear out the authenticated session
    allow_any_instance_of(Sufia::CharacterizationService).to receive(:characterize)
  end

  describe "#create" do
    context "when uploading a file" do
      let(:mock) { GenericFile.new(id: 'test123') }
      let(:batch) { Batch.create }
      let(:batch_id) { batch.id }
      let(:file) { fixture_file_upload('/world.png','image/png') }

      before do
        allow(GenericFile).to receive(:new).and_return(mock)
      end

      context "when the file submitted isn't a file" do
        let(:file) { 'hello' }

        it "should render 422 error" do
          xhr :post, :create, files: [file], Filename: "The World", batch_id: 'sample_batch_id', permission: {"group"=>{"public"=>"read"} }, terms_of_service: '1'
          expect(response.status).to eq 422
          expect(JSON.parse(response.body).first['error']).to match(/no file for upload/i)
        end
      end

      context "when everything is perfect" do
        render_views
        it "spawns a content deposit event job" do
          expect_any_instance_of(Sufia::GenericFile::Actor).to receive(:create_content).with(file, 'world.png', 'image/png').and_return(true)
          xhr :post, :create, files: [file], 'Filename' => 'The world', batch_id: batch_id, permission: {group: { public: 'read' } }, terms_of_service: '1'
          expect(response.body).to eq '[{"name":null,"size":null,"url":"/files/test123","thumbnail_url":"test123","delete_url":"deleteme","delete_type":"DELETE"}]'
          expect(flash[:error]).to be_nil
        end

        it "should create and save a file asset from the given params" do
          date_today = DateTime.now
          allow(DateTime).to receive(:now).and_return(date_today)
          expect {
            xhr :post, :create, files: [file], Filename: "The world", batch_id: batch_id,
                      permission: {"group"=>{"public"=>"read"} }, terms_of_service: '1'
          }.to change { GenericFile.count }.by(1)
          expect(response).to be_success

          saved_file = GenericFile.find('test123')

          # This is confirming that the correct file was attached
          expect(saved_file.label).to eq 'world.png'
          file.rewind
          expect(saved_file.content.content).to eq (file.read)
          # Confirming that date_uploaded and date_modified were set
          expect(saved_file.date_uploaded).to eq date_today.new_offset(0)
          expect(saved_file.date_modified).to eq date_today.new_offset(0)
        end

        it "should set the depositor id" do
          xhr :post, :create, files: [file], Filename: "The world", batch_id: batch_id, permission: {"group"=>{"public"=>"read"} }, terms_of_service: "1"
          expect(response).to be_success

          saved_file = GenericFile.find('test123')
          # This is confirming that apply_depositor_metadata recorded the depositor
          expect(saved_file.depositor).to eq 'jilluser@example.com'
          expect(saved_file.to_solr['depositor_tesim']).to eq ['jilluser@example.com']
        end
      end

      context "when the file has a virus" do
        it "displays a flash error when file has a virus" do
          expect(Sufia::GenericFile::Actor).to receive(:virus_check).with(file.path).and_raise(Sufia::VirusFoundError.new('A virus was found'))
          xhr :post, :create, files: [file], Filename: "The world", batch_id: "sample_batch_id", permission: {"group"=>{"public"=>"read"} }, terms_of_service: '1'
          expect(flash[:error]).not_to be_blank
          expect(flash[:error]).to include('A virus was found')
        end
      end

      context "when solr continuously has errors" do
        it "should error out of create and save after on continuos rsolr error" do
          allow_any_instance_of(GenericFile).to receive(:save).and_raise(RSolr::Error::Http.new({},{}))

          file = fixture_file_upload('/world.png','image/png')
          xhr :post, :create, files: [file], Filename: "The world", batch_id: "sample_batch_id", permission: {"group"=>{"public"=>"read"} }, terms_of_service: "1"
          expect(response.body).to include("Error occurred while creating generic file.")
        end
      end

      context "when a work id is passed" do
        let (:work) { GenericWork.new {|w| w.apply_depositor_metadata(user); w.save! } }
        it "records the work" do
          xhr :post, :create, files: [file], Filename: 'The world', batch_id: batch_id, work_id: work.id, terms_of_service: '1'
          expect(response).to be_success
          saved_file = GenericFile.find('test123')
          expect(saved_file.generic_work_id).to eq work.id
          expect(saved_file.generic_work).to eq work
        end

      end
      context "when a work id is not passed" do
        it "creates the work" do
          xhr :post, :create, files: [file], Filename: 'The world', batch_id: batch_id, terms_of_service: '1'
          expect(response).to be_success
          saved_file = GenericFile.find('test123')
          expect(saved_file.generic_work_id).not_to be_nil
        end

      end

    end

    context "with browse-everything" do
      let(:batch) { Batch.create }
      let(:batch_id) { batch.id }

      before do
        @json_from_browse_everything = {"0"=>{"url"=>"https://dl.dropbox.com/fake/blah-blah.filepicker-demo.txt.txt", "expires"=>"2014-03-31T20:37:36.214Z", "file_name"=>"filepicker-demo.txt.txt"}, "1"=>{"url"=>"https://dl.dropbox.com/fake/blah-blah.Getting%20Started.pdf", "expires"=>"2014-03-31T20:37:36.731Z", "file_name"=>"Getting+Started.pdf"}}
      end
      it "should ingest files from provide URLs" do
        expect(ImportUrlJob).to receive(:new).twice {"ImportJob"}
        expect(Sufia.queue).to receive(:push).with("ImportJob").twice
        expect { post :create, selected_files: @json_from_browse_everything, batch_id: batch_id }.to change(GenericFile, :count).by(2)
        created_files = GenericFile.all
        ["https://dl.dropbox.com/fake/blah-blah.Getting%20Started.pdf", "https://dl.dropbox.com/fake/blah-blah.filepicker-demo.txt.txt"].each do |url|
          expect(created_files.map {|f| f.import_url}).to include(url)
        end
        ["filepicker-demo.txt.txt","Getting+Started.pdf"].each do |filename|
          expect(created_files.map {|f| f.label}).to include(filename)
        end
      end


      context "when a work id is passed" do
        let (:work) { GenericWork.new {|w| w.apply_depositor_metadata(user); w.save! } }
        it "records the work" do
          expect(ImportUrlJob).to receive(:new).twice {"ImportJob"}
          expect(Sufia.queue).to receive(:push).with("ImportJob").twice
          expect { post :create, selected_files: @json_from_browse_everything, batch_id: batch_id, work_id: work.id }.to change(GenericFile, :count).by(2)
          created_files = GenericFile.all
          created_files.each {|f| expect(f.generic_work).to eq work}
        end

      end
      context "when a work id is not passed" do
        it "creates the work" do
          expect(ImportUrlJob).to receive(:new).twice {"ImportJob"}
          expect(Sufia.queue).to receive(:push).with("ImportJob").twice
          expect { post :create, selected_files: @json_from_browse_everything, batch_id: batch_id }.to change(GenericFile, :count).by(2)
          created_files = GenericFile.all
          expect(created_files[0].generic_work).not_to eq created_files[1].generic_work
        end

      end


    end

    context "with local_file" do
      let(:mock_url) {"http://example.com"}
      let(:mock_upload_directory) { 'spec/mock_upload_directory' }
      let(:batch) { Batch.create }
      let(:batch_id) { batch.id }

      before do
        Sufia.config.enable_local_ingest = true
        FileUtils.mkdir_p([File.join(mock_upload_directory, "import/files"), File.join(mock_upload_directory, "import/metadata")])
        FileUtils.copy(File.expand_path('../../fixtures/world.png', __FILE__), mock_upload_directory)
        FileUtils.copy(File.expand_path('../../fixtures/image.jpg', __FILE__), mock_upload_directory)
        FileUtils.copy(File.expand_path('../../fixtures/dublin_core_rdf_descMetadata.nt', __FILE__), File.join(mock_upload_directory, "import/metadata"))
        FileUtils.copy(File.expand_path('../../fixtures/icons.zip', __FILE__), File.join(mock_upload_directory, "import/files"))
        FileUtils.copy(File.expand_path('../../fixtures/Example.ogg', __FILE__), File.join(mock_upload_directory, "import/files"))
      end

      after do
        Sufia.config.enable_local_ingest = false
      end

      context "when User model defines a directory path" do
        before do
          allow_any_instance_of(User).to receive(:directory).and_return(mock_upload_directory)
        end

        it "should ingest files from the filesystem" do
          expect {
            post :create, local_file: ["world.png", "image.jpg"], batch_id: batch_id
          }.to change(GenericFile, :count).by(2)
          expect(response).to redirect_to Sufia::Engine.routes.url_helpers.batch_edit_path(batch_id)
          # These files should have been moved out of the upload directory
          expect(File).not_to exist("#{mock_upload_directory}/image.jpg")
          expect(File).not_to exist("#{mock_upload_directory}/world.png")
          # And into the storage directory
          files = Batch.find(batch_id).generic_files
          expect(files.first.label).to eq('world.png')
          expect(files.to_a.map(&:label)).to eq ['world.png', 'image.jpg']
        end

        it "should ingest redirect to another location" do
          expect(GenericFilesController).to receive(:upload_complete_path).and_return(mock_url)
          expect {
            post :create, local_file: ["world.png"], batch_id: batch_id
          }.to change(GenericFile, :count).by(1)
          expect(response).to redirect_to mock_url
          # These files should have been moved out of the upload directory
          expect(File).not_to exist("#{mock_upload_directory}/world.png")
          # And into the storage directory
          files = Batch.find(batch_id).generic_files
          expect(files.first.label).to eq 'world.png'
        end

        it "should ingest directories from the filesystem" do
          expect {
            post :create, local_file: ["world.png", "import"], batch_id: batch_id
          }.to change(GenericFile, :count).by(4)
          expect(response).to redirect_to Sufia::Engine.routes.url_helpers.batch_edit_path(batch_id)
          # These files should have been moved out of the upload directory
          expect(File).not_to exist("#{mock_upload_directory}/import/files/icons.zip")
          expect(File).not_to exist("#{mock_upload_directory}/import/metadata/dublin_core_rdf_descMetadata.nt")
          expect(File).not_to exist("#{mock_upload_directory}/world.png")
          # And into the storage directory
          files = Batch.find(batch_id).generic_files
          file_labels = files.map {|f| f.label}
          expect(file_labels).to include 'world.png'
          # TODO: use files.select once projecthydra/active_fedora#609 is fixed
          ['icons.zip', 'Example.ogg'].each do |filename|
            expect(files.map { |f| f.relative_path if f.label.match(filename) }.compact.first).to eq "import/files/#{filename}"
          end
          expect(files.map { |f| f.relative_path if f.label.match("dublin_core_rdf_descMetadata.nt") }.compact.first).to eq 'import/metadata/dublin_core_rdf_descMetadata.nt'
        end

        context "when a work id is passed" do
          let (:work) { GenericWork.new {|w| w.apply_depositor_metadata(user); w.save! } }
          it "records the work" do
            expect {
              post :create, local_file: ["world.png", "image.jpg"], batch_id: batch_id, work_id: work.id
            }.to change(GenericFile, :count).by(2)
            created_files = GenericFile.all
            created_files.each {|f| expect(f.generic_work).to eq work}
          end

        end

        context "when a work id is not passed" do
          it "creates the work" do
            expect {
              post :create, local_file: ["world.png", "image.jpg"], batch_id: batch_id
            }.to change(GenericFile, :count).by(2)
            created_files = GenericFile.all
            expect(created_files[0].generic_work).not_to eq created_files[1].generic_work
          end

        end
      end

      context "when User model does not define directory path" do
        it "should return an error message and redirect to file upload page" do
          expect {
            post :create, local_file: ["world.png", "image.jpg"], batch_id: batch_id
          }.to_not change(GenericFile, :count)
          expect(response).to render_template :new
          expect(flash[:alert]).to eq 'Your account is not configured for importing files from a user-directory on the server.'
        end
      end
    end
  end

  describe "audit" do
    let(:generic_file) do
      GenericFile.create do |gf|
        gf.add_file(File.open(fixture_path + '/world.png'), path: 'content', original_name: 'world.png')
        gf.apply_depositor_metadata(user)
      end
    end

    it "should return json with the result" do
      xhr :post, :audit, id: generic_file
      expect(response).to be_success
      json = JSON.parse(response.body)
      audit_results = json.collect { |result| result["pass"] }
      expect(audit_results.reduce(true) { |sum, value| sum && value }).to eq 999 # never been audited
    end
  end

  describe "destroy" do
    let(:generic_file) do
      GenericFile.create do |gf|
        gf.apply_depositor_metadata(user)
      end
    end

    before do
      allow(ContentDeleteEventJob).to receive(:new).with(generic_file.id, user.user_key).and_return(delete_message)
    end
    let(:delete_message) { double('delete message') }
    it "should delete the file" do
      expect(Sufia.queue).to receive(:push).with(delete_message)
      expect {
        delete :destroy, id: generic_file
      }.to change { GenericFile.exists?(generic_file.id) }.from(true).to(false)
    end
  end

  describe 'stats' do
    let(:generic_file) do
      GenericFile.create do |gf|
        gf.apply_depositor_metadata(user)
      end
    end

    context 'when user has access to file' do
      before do
        sign_in user
        mock_query = double('query')
        allow(mock_query).to receive(:for_path).and_return([
            OpenStruct.new(date: '2014-01-01', pageviews: 4),
            OpenStruct.new(date: '2014-01-02', pageviews: 8),
            OpenStruct.new(date: '2014-01-03', pageviews: 6),
            OpenStruct.new(date: '2014-01-04', pageviews: 10),
            OpenStruct.new(date: '2014-01-05', pageviews: 2)])
        allow(mock_query).to receive(:map).and_return(mock_query.for_path.map(&:marshal_dump))
        profile = double('profile')
        allow(profile).to receive(:sufia__pageview).and_return(mock_query)
        allow(Sufia::Analytics).to receive(:profile).and_return(profile)

        download_query = double('query')
        allow(download_query).to receive(:for_file).and_return([
          OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "123456789", totalEvents: "3")
        ])
        allow(download_query).to receive(:map).and_return(download_query.for_file.map(&:marshal_dump))
        allow(profile).to receive(:sufia__download).and_return(download_query)
      end

      it 'renders the stats view' do
        allow(controller.request).to receive(:referer).and_return('foo')
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.my.files'), Sufia::Engine.routes.url_helpers.dashboard_files_path)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.generic_file.browse_view'), Sufia::Engine.routes.url_helpers.generic_file_path(generic_file))
        get :stats, id: generic_file
        expect(response).to be_success
        expect(response).to render_template(:stats)
      end

      context "user is not signed in but the file is public" do
        before do
          generic_file.read_groups = ['public']
          generic_file.save
        end

        it 'renders the stats view' do
          get :stats, id: generic_file
          expect(response).to be_success
          expect(response).to render_template(:stats)
        end
      end
    end

    context 'when user lacks access to file' do
      before do
        sign_in FactoryGirl.create(:user)
      end

      it 'redirects to root_url' do
        get :stats, id: generic_file
        expect(response).to redirect_to(Sufia::Engine.routes.url_helpers.root_path)
      end
    end
  end

  describe "#edit" do
    let(:generic_file) do
      GenericFile.create do |gf|
        gf.apply_depositor_metadata(user)
      end
    end

    it "should set the breadcrumbs and versions presenter" do
      allow(controller.request).to receive(:referer).and_return('foo')
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.my.files'), Sufia::Engine.routes.url_helpers.dashboard_files_path)
      expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.generic_file.browse_view'), Sufia::Engine.routes.url_helpers.generic_file_path(generic_file))
      get :edit, id: generic_file

      expect(response).to be_success
      expect(assigns[:generic_file]).to eq generic_file
      expect(assigns[:form]).to be_kind_of CurationConcerns::Forms::GenericFileEditForm
      expect(assigns[:version_list]).to be_kind_of Sufia::VersionListPresenter
      expect(response).to render_template(:edit)
    end
  end

  describe "update" do
    let(:generic_file) do
      GenericFile.create do |gf|
        gf.apply_depositor_metadata(user)
      end
    end

    context "when updating metadata" do
      let(:update_message) { double('content update message') }
      before do
        allow(ContentUpdateEventJob).to receive(:new).with(generic_file.id, 'jilluser@example.com').and_return(update_message)
      end

      it "should spawn a content update event job" do
        expect(Sufia.queue).to receive(:push).with(update_message)
        post :update, id: generic_file, generic_file: { title: ['new_title'], tag: [''],
                                                        permissions_attributes: [{ type: 'person', name: 'archivist1', access: 'edit'}] }
      end

      it "spawns a content new version event job" do
        s1 = double('one')
        allow(ContentNewVersionEventJob).to receive(:new).with(generic_file.id, 'jilluser@example.com').and_return(s1)
        expect(Sufia.queue).to receive(:push).with(s1).once

        s2 = double('one')
        allow(CharacterizeJob).to receive(:new).with(generic_file.id).and_return(s2)
        expect(Sufia.queue).to receive(:push).with(s2).once
        file = fixture_file_upload('/world.png', 'image/png')
        post :update, id: generic_file, filedata: file, generic_file: {tag: [''], permissions: { new_user_name: {archivist1: 'edit' } } }
      end
    end

    context "when updating the attached file" do
      it "spawns a content new version event job" do
        s1 = double('one')
        allow(ContentNewVersionEventJob).to receive(:new).with(generic_file.id, 'jilluser@example.com').and_return(s1)
        expect(Sufia.queue).to receive(:push).with(s1).once

        s2 = double('one')
        allow(CharacterizeJob).to receive(:new).with(generic_file.id).and_return(s2)
        expect(Sufia.queue).to receive(:push).with(s2).once

        file = fixture_file_upload('/world.png', 'image/png')
        post :update, id: generic_file, filedata: file, generic_file: {tag: [''],
                                                        permissions_attributes: [{ type: 'user', name: 'archivist1', access: 'edit'}] }
      end
    end

    context "with two existing versions from different users" do

      let(:file1)       { "world.png" }
      let(:file1_type)  { "image/png" }
      let(:file2)       { "image.jpg" }
      let(:file2_type)  { "image/jpeg" }
      let(:second_user) { FactoryGirl.create(:user) }
      let(:version1)    { "version1" }
      let(:actor1)      { Sufia::GenericFile::Actor.new(generic_file, user) }
      let(:actor2)      { Sufia::GenericFile::Actor.new(generic_file, second_user) }

      before do
        actor1.create_content(fixture_file_upload(file1), file1, file1_type)
        actor2.create_content(fixture_file_upload(file2), file2, file2_type)
      end

      describe "restoring a previous version" do
        context "as the first user" do
          before do
            sign_in user
            post :update, id: generic_file, revision: version1
          end

          let(:restored_content) { generic_file.reload.content }
          let(:versions)         { restored_content.versions }
          let(:latest_version)   { Sufia::VersioningService.latest_version_of(restored_content) }

          it "restores the first versions's content and metadata" do
            expect(restored_content.mime_type).to eq file1_type
            expect(restored_content.original_name).to eq file1
            expect(versions.all.count).to eq 4
            expect(versions.last.label).to eq latest_version.label
            expect(VersionCommitter.where(version_id: versions.last.uri).pluck(:committer_login)).to eq [user.user_key]
          end
        end

        context "as the second user" do
          before do
            sign_in second_user
          end
          it "should not create a new version" do
            post :update, id: generic_file, revision: version1
            expect(response).to be_redirect
          end
        end
      end
    end

    it "should add new groups and users" do
      post :update, id: generic_file,
        generic_file: { tag: [''],
                        permissions_attributes: [
                          { type: 'person', name: 'user1', access: 'edit' },
                          { type: 'group', name: 'group1', access: 'read' }
                        ]
                      }

      expect(assigns[:generic_file].read_groups).to eq ["group1"]
      expect(assigns[:generic_file].edit_users).to include("user1", user.user_key)
    end

    it "should update existing groups and users" do
      generic_file.edit_groups = ['group3']
      generic_file.save
      post :update, id: generic_file,
        generic_file: { tag: [''],
                        permissions_attributes: [
                          { id: generic_file.permissions.last.id, type: 'group', name: 'group3', access: 'read'}
                        ]
                      }

      expect(assigns[:generic_file].read_groups).to eq(["group3"])
    end

    it "spawns a virus check" do
      s1 = double('one')
      allow(ContentNewVersionEventJob).to receive(:new).with(generic_file.id, 'jilluser@example.com').and_return(s1)
      expect(Sufia.queue).to receive(:push).with(s1).once

      s2 = double('one')
      allow(CharacterizeJob).to receive(:new).with(generic_file.id).and_return(s2)
      allow(CreateDerivativesJob).to receive(:new).with(generic_file.id).and_return(s2)
      file = fixture_file_upload('/world.png', 'image/png')
      expect(Sufia::GenericFile::Actor).to receive(:virus_check).and_return(0)
      expect(Sufia.queue).to receive(:push).with(s2).once
      post :update, id: generic_file.id, filedata: file, 'Filename' => 'The world',
          generic_file: { tag: [''],
                          permissions_attributes: [{ type: 'user', name: 'archivist1', access: 'edit' }] }
    end

    context "when there's an error saving" do
      let!(:generic_file) do
        GenericFile.create do |gf|
          gf.apply_depositor_metadata(user)
        end
      end
      it "redirects to edit" do
        expect_any_instance_of(GenericFile).to receive(:valid?).and_return(false)
        post :update, id: generic_file, generic_file: {:tag=>['']}
        expect(response).to be_successful
        expect(response).to render_template('edit')
        expect(assigns[:generic_file]).to eq generic_file
        expect(flash[:error]).to include 'Update was unsuccessful.'
      end
    end
  end

  describe "someone elses files" do
    let(:generic_file) do
      GenericFile.create(id: 'test5') do |f|
        f.apply_depositor_metadata('archivist1@example.com')
        f.add_file(File.open(fixture_path + '/world.png'), path: 'content', original_name: 'world.png')
        # grant public read access explicitly
        f.read_groups = ['public']
      end
    end

    describe "edit" do
      it "should give me a flash error" do
        get :edit, id: generic_file
        expect(response).to redirect_to @routes.url_helpers.generic_file_path('test5')
        expect(flash[:alert]).not_to be_nil
        expect(flash[:alert]).not_to be_empty
        expect(flash[:alert]).to include("You do not have sufficient privileges to edit this document")
      end
    end

    describe "#show" do
      it "should show me the file and set breadcrumbs" do
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
        get :show, id: generic_file
        expect(response).to be_successful
        expect(flash).to be_empty
        expect(assigns[:events]).to be_kind_of Array
        expect(assigns[:generic_file]).to eq generic_file
        expect(assigns[:audit_status]).to eq 'Audits have not yet been run on this file.'
      end
      it 'renders an endnote file' do
        get :show, id: generic_file, format: 'endnote'
        expect(response).to be_successful
      end
    end
  end

  describe "flash" do
    it "should not let the user submit if they logout" do
      sign_out user
      get :new
      expect(response).to_not be_success
      expect(flash[:alert]).to include("You need to sign in or sign up before continuing")
    end
    it "should filter flash if they signin" do
      sign_in user
      get :new
      expect(flash[:alert]).to be_nil
    end
  end

  describe "notifications" do
    before do
      User.audituser.send_message(user, "Test message", "Test subject")
    end
    it "should display notifications" do
      get :new
      expect(assigns[:notify_number]).to eq 1
      expect(user.mailbox.inbox[0].messages[0].subject).to eq "Test subject"
    end
  end

  describe "batch creation" do
    context "when uploading a file" do
      let(:batch_id) { ActiveFedora::Noid::Service.new.mint }
      let(:file1) { fixture_file_upload('/world.png','image/png') }
      let(:file2) { fixture_file_upload('/image.jpg','image/png') }

      it "should not create the batch on HTTP GET " do
        expect(Batch).to_not receive(:create)
        xhr :get, :new
        expect(response).to be_success
      end

      it "should create the batch on HTTP POST with multiple files" do
        expect(GenericFile).to receive(:new).twice
        expect(Batch).to receive(:find_or_create).twice
        xhr :post, :create, files: [file1], Filename: 'The world 1', batch_id: batch_id, on_behalf_of: 'carolyn', terms_of_service: '1'
        expect(response).to be_success
        xhr :post, :create, files: [file2], Filename: 'An image', batch_id: batch_id, on_behalf_of: 'carolyn', terms_of_service: '1'
        expect(response).to be_success
      end
    end
  end
end
