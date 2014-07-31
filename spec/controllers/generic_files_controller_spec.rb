require 'spec_helper'

describe GenericFilesController, :type => :controller do
  before do
    allow(controller).to receive(:has_access?).and_return(true)
    @user = FactoryGirl.find_or_create(:jill)
    sign_in @user
    allow_any_instance_of(User).to receive(:groups).and_return([])
    allow(controller).to receive(:clear_session_user) ## Don't clear out the authenticated session
    allow_any_instance_of(GenericFile).to receive(:characterize)
  end

  describe "#create" do
    before do
      @file_count = GenericFile.count
      mock = GenericFile.new(pid: 'test123')
      allow(GenericFile).to receive(:new).and_return(mock)
    end

    let(:batch) { Batch.create }
    let(:batch_id) { batch.id }
    let(:file) { fixture_file_upload('/world.png','image/png') }

    it "should record on_behalf_of" do
      file = fixture_file_upload('/world.png','image/png')
      xhr :post, :create, files: [file], Filename: 'The world', batch_id: 'sample:batch_id', on_behalf_of: 'carolyn', terms_of_service: '1'
      expect(response).to be_success
      saved_file = GenericFile.find('test123')
      expect(saved_file.on_behalf_of).to eq 'carolyn'
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
      it "spawns a content deposit event job" do
        expect_any_instance_of(Sufia::GenericFile::Actor).to receive(:create_content).with(file, 'world.png', 'content').and_return(true)
        xhr :post, :create, files: [file], 'Filename' => 'The world', batch_id: batch_id, permission: {group: { public: 'read' } }, terms_of_service: '1'
        expect(flash[:error]).to be_nil
      end

      it "should create and save a file asset from the given params" do
        date_today = Date.today
        allow(Date).to receive(:today).and_return(date_today)
        xhr :post, :create, files: [file], Filename: "The world", batch_id: batch_id, permission: {"group"=>{"public"=>"read"} }, terms_of_service: '1'
        expect(response).to be_success
        expect(GenericFile.count).to eq(@file_count + 1)

        saved_file = GenericFile.find('test123')

        # This is confirming that the correct file was attached
        expect(saved_file.label).to eq 'world.png'
        expect(saved_file.content.checksum).to eq 'f794b23c0c6fe1083d0ca8b58261a078cd968967'
        expect(saved_file.content.dsChecksumValid).to be true

        # Confirming that date_uploaded and date_modified were set
        expect(saved_file.date_uploaded).to eq date_today
        expect(saved_file.date_modified).to eq date_today
      end

      it "should record what user created the first version of content" do
        xhr :post, :create, files: [file], Filename: "The world", batch_id: batch_id, permission: {"group"=>{"public"=>"read"} }, terms_of_service: "1"
        saved_file = GenericFile.find('test123')
        version = saved_file.content.latest_version
        expect(version.versionID).to eq "content.0"
        expect(saved_file.content.version_committer(version)).to eq @user.user_key
      end

      it "should create batch associations from batch_id" do
        skip "we need to create the batch, because Fedora 4 doesn't let us set associations to things that don't exist"
        batch_id = "object-that-doesnt-exist"
        allow(Sufia.config).to receive(:id_namespace).and_return('sample')
        allow(controller).to receive(:add_posted_blob_to_asset)
        xhr :post, :create, files: [file], Filename: "The world", batch_id: batch_id, permission: {"group"=>{"public"=>"read"} }, terms_of_service: "1"
        allow(GenericFile).to receive(:new).and_call_original
        expect { Batch.find(batch_id) }.to raise_error(ActiveFedora::ObjectNotFoundError) # The controller shouldn't actually save the Batch, but it should write the batch id to the files.
        batch = Batch.create(pid: batch_id)
        expect(batch.generic_files.first.pid).to eq "test123"
      end

      it "should set the depositor id" do
        xhr :post, :create, files: [file], Filename: "The world", batch_id: batch_id, permission: {"group"=>{"public"=>"read"} }, terms_of_service: "1"
        expect(response).to be_success

        saved_file = GenericFile.find('test123')
        # This is confirming that apply_depositor_metadata recorded the depositor
        expect(saved_file.properties.depositor).to eq ['jilluser@example.com']
        expect(saved_file.depositor).to eq 'jilluser@example.com'
        expect(saved_file.properties.to_solr.keys).to include('depositor_tesim')
        expect(saved_file.properties.to_solr['depositor_tesim']).to eq ['jilluser@example.com']
        expect(saved_file.to_solr.keys).to include('depositor_tesim')
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
  end

  describe "#create with browse-everything" do
    before do
      @json_from_browse_everything = {"0"=>{"url"=>"https://dl.dropbox.com/fake/blah-blah.filepicker-demo.txt.txt", "expires"=>"2014-03-31T20:37:36.214Z", "file_name"=>"filepicker-demo.txt.txt"}, "1"=>{"url"=>"https://dl.dropbox.com/fake/blah-blah.Getting%20Started.pdf", "expires"=>"2014-03-31T20:37:36.731Z", "file_name"=>"Getting+Started.pdf"}}
    end
    it "should ingest files from provide URLs" do
      expect(ImportUrlJob).to receive(:new).twice {"ImportJob"}
      expect(Sufia.queue).to receive(:push).with("ImportJob").twice
      expect { post :create, selected_files: @json_from_browse_everything, batch_id: "sample_batch_id" }.to change(GenericFile, :count).by(2)
      created_files = GenericFile.all
      ["https://dl.dropbox.com/fake/blah-blah.Getting%20Started.pdf", "https://dl.dropbox.com/fake/blah-blah.filepicker-demo.txt.txt"].each do |url|
        expect(created_files.map {|f| f.import_url}).to include(url)
      end
      ["filepicker-demo.txt.txt","Getting+Started.pdf"].each do |filename|
        expect(created_files.map {|f| f.label}).to include(filename)
      end
    end
  end

  describe "#create with local_file" do
    let (:mock_url) {"http://example.com"}
    before do
      Sufia.config.enable_local_ingest = true
      @mock_upload_directory = 'spec/mock_upload_directory'
      # Dir.mkdir @mock_upload_directory unless File.exists? @mock_upload_directory
      FileUtils.mkdir_p([File.join(@mock_upload_directory, "import/files"),File.join(@mock_upload_directory, "import/metadata")])
      FileUtils.copy(File.expand_path('../../fixtures/world.png', __FILE__), @mock_upload_directory)
      FileUtils.copy(File.expand_path('../../fixtures/image.jpg', __FILE__), @mock_upload_directory)
      FileUtils.copy(File.expand_path('../../fixtures/dublin_core_rdf_descMetadata.nt', __FILE__), File.join(@mock_upload_directory, "import/metadata"))
      FileUtils.copy(File.expand_path('../../fixtures/icons.zip', __FILE__), File.join(@mock_upload_directory, "import/files"))
      FileUtils.copy(File.expand_path('../../fixtures/Example.ogg', __FILE__), File.join(@mock_upload_directory, "import/files"))
    end
    after do
      Sufia.config.enable_local_ingest = false
      allow_any_instance_of(FileContentDatastream).to receive(:live?).and_return(true)
      GenericFile.destroy_all
    end
    context "when User model defines a directory path" do
      before do
        if $in_travis
          # In order to avoid an invalid derivative creation, just stub out the derivatives.
          allow_any_instance_of(GenericFile).to receive(:create_derivatives)
        end
        allow_any_instance_of(User).to receive(:directory).and_return(@mock_upload_directory)
      end
      it "should ingest files from the filesystem" do
        expect { post :create, local_file: ["world.png", "image.jpg"], batch_id: "xw42n7934"}.to change(GenericFile, :count).by(2)
        expect(response).to redirect_to Sufia::Engine.routes.url_helpers.batch_edit_path('xw42n7934')
        # These files should have been moved out of the upload directory
        expect(File).not_to exist("#{@mock_upload_directory}/image.jpg")
        expect(File).not_to exist("#{@mock_upload_directory}/world.png")
        # And into the storage directory
        files = GenericFile.find(Solrizer.solr_name("is_part_of",:symbol) => 'info:fedora/xw42n7934')
        expect(files.first.label).to eq('world.png')
        expect(files.last.label).to eq('image.jpg')
      end
      it "should ingest redirect to another location" do
        expect(GenericFilesController).to receive(:upload_complete_path).and_return(mock_url)
        expect { post :create, local_file: ["world.png"], batch_id: "xw42n7934"}.to change(GenericFile, :count).by(1)
        expect(response).to redirect_to mock_url
        # These files should have been moved out of the upload directory
        expect(File).not_to exist("#{@mock_upload_directory}/world.png")
        # And into the storage directory
        files = GenericFile.find(Solrizer.solr_name("is_part_of",:symbol) => 'info:fedora/xw42n7934')
        expect(files.first.label).to eq('world.png')
      end
      it "should ingest directories from the filesystem" do
        expect { post :create, local_file: ["world.png", "import"], batch_id: "xw42n7934"}.to change(GenericFile, :count).by(4)
        expect(response).to redirect_to Sufia::Engine.routes.url_helpers.batch_edit_path('xw42n7934')
        # These files should have been moved out of the upload directory
        expect(File).not_to exist("#{@mock_upload_directory}/import/files/icons.zip")
        expect(File).not_to exist("#{@mock_upload_directory}/import/metadata/dublin_core_rdf_descMetadata.nt")
        expect(File).not_to exist("#{@mock_upload_directory}/world.png")
        # And into the storage directory
        files = GenericFile.find(Solrizer.solr_name("is_part_of",:symbol) => 'info:fedora/xw42n7934')
        expect(files.first.label).to eq('world.png')
        ['icons.zip', 'Example.ogg'].each do |filename|
          expect(files.select{|f| f.label == filename}.first.relative_path).to eq("import/files/#{filename}")
        end
        expect(files.select{|f| f.label == 'dublin_core_rdf_descMetadata.nt'}.first.relative_path).to eq('import/metadata/dublin_core_rdf_descMetadata.nt')
      end
    end
    context "when User model does not define directory path" do
      it "should return an error message and redirect to file upload page" do
        expect { post :create, local_file: ["world.png", "image.jpg"], batch_id: "xw42n7934"}.not_to change(GenericFile, :count)
        expect(response).to render_template :new
        expect(flash[:alert]).to eq('Your account is not configured for importing files from a user-directory on the server.')
      end
    end
  end

  describe "audit" do
    before do
      @generic_file = GenericFile.new
      @generic_file.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      @generic_file.apply_depositor_metadata('mjg36')
      @generic_file.save
    end
    it "should return json with the result" do
      xhr :post, :audit, id: @generic_file.pid
      expect(response).to be_success
      expect { JSON.parse(response.body) }.not_to raise_error
      audit_results = JSON.parse(response.body).collect { |result| result["pass"] }
      expect(audit_results.reduce(true) { |sum, value| sum && value }).to be_truthy
    end
  end

  describe "destroy" do
    before(:each) do
      @generic_file = GenericFile.new
      @generic_file.apply_depositor_metadata(@user)
      @generic_file.save
      @user = FactoryGirl.find_or_create(:jill)
      sign_in @user
    end
    it "should delete the file" do
      expect(GenericFile.find(@generic_file.pid)).not_to be_nil
      delete :destroy, id: @generic_file.pid
      expect { GenericFile.find(@generic_file.pid) }.to raise_error(ActiveFedora::ObjectNotFoundError)
    end
    it "should spawn a content delete event job" do
      s1 = double('one')
      expect(ContentDeleteEventJob).to receive(:new).with(@generic_file.pid, @user.user_key).and_return(s1)
      expect(Sufia.queue).to receive(:push).with(s1).once
      delete :destroy, id: @generic_file.pid
    end

    context "when the file is featured" do
      before do
        FeaturedWork.create(generic_file_id: @generic_file.pid)
      end
      it "should make the file not featured" do
        expect(FeaturedWorkList.new.featured_works.map(&:generic_file_id)).to include(@generic_file.pid)
        delete :destroy, id: @generic_file.pid
        expect(FeaturedWorkList.new.featured_works.map(&:generic_file_id)).to_not include(@generic_file.pid)
      end
    end
  end

  describe 'stats' do
    before do
      @generic_file = GenericFile.new.tap do |gf|
        gf.apply_depositor_metadata(@user)
        gf.save
      end
    end

    after do
      @generic_file.destroy
    end

    context 'when user has access to file' do
      before do
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
        get :stats, id: @generic_file.noid
        expect(response).to be_success
        expect(response).to render_template(:stats)
      end

      context "user is not signed in but the file is public" do
        before do
          sign_out @user
          @generic_file.read_groups = ['public']
          @generic_file.save
        end

        it 'renders the stats view' do
          get :stats, id: @generic_file.noid
          expect(response).to be_success
          expect(response).to render_template(:stats)
        end
      end
    end

    context 'when user lacks access to file' do
      before do
        @archivist = FactoryGirl.find_or_create(:archivist)
        sign_in @archivist
      end

      it 'redirects to root_url' do
        get :stats, id: @generic_file.pid
        expect(response).to redirect_to(Sufia::Engine.routes.url_helpers.root_path)
      end
    end
  end

  describe "update" do
    let(:generic_file) do
      GenericFile.new.tap do |gf|
        gf.apply_depositor_metadata(@user)
        gf.save!
      end
    end

    after do
      generic_file.destroy
    end

    it "should spawn a content update event job" do
      s1 = double('one')
      expect(ContentUpdateEventJob).to receive(:new).with(generic_file.pid, 'jilluser@example.com').and_return(s1)
      expect(Sufia.queue).to receive(:push).with(s1).once
      @user = FactoryGirl.find_or_create(:jill)
      sign_in @user
      post :update, id: generic_file, generic_file: {title: ['new_title'], tag: [''], permissions: { new_user_name: {'archivist1'=>'edit'}}}
      @user.delete
    end

    it "spawns a content new version event job" do
      s1 = double('one')
      allow(ContentNewVersionEventJob).to receive(:new).with(generic_file.pid, 'jilluser@example.com').and_return(s1)
      expect(Sufia.queue).to receive(:push).with(s1).once

      s2 = double('one')
      allow(CharacterizeJob).to receive(:new).with(generic_file.pid).and_return(s2)
      expect(Sufia.queue).to receive(:push).with(s2).once
      @user = FactoryGirl.find_or_create(:jill)
      sign_in @user

      file = fixture_file_upload('/world.png', 'image/png')
      post :update, id: generic_file, filedata: file, generic_file: {tag: [''], permissions: { new_user_name: {archivist1: 'edit' } } }
      @user.destroy
    end

    it "should change mime type when restoring a revision with a different mime type" do
      @user = FactoryGirl.find_or_create(:jill)
      sign_in @user

      file = fixture_file_upload('/world.png','image/png')
      post :update, id: generic_file, filedata: file, generic_file: { tag: [''], permissions: { new_user_name: { 'archivist1@example.com'=>'edit' } } }

      posted_file = GenericFile.find(generic_file.pid)
      version1 = posted_file.content.latest_version
      expect(posted_file.content.version_committer(version1)).to eq(@user.user_key)

      file = fixture_file_upload('/image.jpg','image/jpg')
      post :update, id: generic_file, filedata: file, generic_file: { tag: [''], permissions: { new_user_name: { 'archivist1@example.com'=>'edit' } } }

      posted_file = GenericFile.find(generic_file.pid)
      version2 = posted_file.content.latest_version
      expect(posted_file.content.version_committer(version2)).to eq(@user.user_key)

      expect(posted_file.content.mimeType).to eq("image/jpeg")
      post :update, id: generic_file, revision: 'content.0'

      restored_file = GenericFile.find(generic_file.pid)
      version3 = restored_file.content.latest_version
      expect(version3.versionID).not_to eq(version2.versionID)
      expect(version3.versionID).not_to eq(version1.versionID)
      expect(restored_file.content.version_committer(version3)).to eq(@user.user_key)
      expect(restored_file.content.mimeType).to eq("image/png")
      @user.delete
    end

    context "when two users edit a file" do
      let(:archivist) { FactoryGirl.find_or_create(:archivist) }
      let(:user) { FactoryGirl.find_or_create(:jill) }
      let(:generic_file) do
        GenericFile.new.tap do |gf|
          gf.apply_depositor_metadata(user)
          gf.edit_users = [user.user_key, archivist.user_key]
          gf.save!
        end
      end
      before do
        allow_any_instance_of(Sufia::GenericFile::Actor).to receive(:push_characterize_job)
        sign_in user
      end

      it "records which user added a new version" do
        file = fixture_file_upload('/world.png','image/png')
        post :update, id: generic_file, filedata: file

        posted_file = GenericFile.find(generic_file.pid)
        version1 = posted_file.content.latest_version
        expect(posted_file.content.version_committer(version1)).to eq(user.user_key)

        # other user uploads new version
        # TODO this should be a separate test
        allow(controller).to receive(:current_user).and_return(archivist)
        # reset controller:
        controller.instance_variable_set(:@actor, nil)

        expect(ContentUpdateEventJob).to receive(:new).with(generic_file.pid, 'jilluser@example.com').never

        s1 = double('one')
        allow(ContentNewVersionEventJob).to receive(:new).with(generic_file.pid, archivist.user_key).and_return(s1)
        expect(Sufia.queue).to receive(:push).with(s1).once

        file = fixture_file_upload('/image.jpg', 'image/jpg')
        post :update, id: generic_file, filedata: file

        edited_file = generic_file.reload
        version2 = edited_file.content.latest_version
        expect(version2.versionID).not_to eq(version1.versionID)
        expect(edited_file.content.version_committer(version2)).to eq(archivist.user_key)

        # original user restores his or her version
        allow(controller).to receive(:current_user).and_return(user)
        sign_in user
        expect(ContentUpdateEventJob).to receive(:new).with(generic_file.pid, 'jilluser@example.com').never
        s1 = double('one')
        allow(ContentRestoredVersionEventJob).to receive(:new).with(generic_file.pid, user.user_key, 'content.0').and_return(s1)
        expect(Sufia.queue).to receive(:push).with(s1).once

        # reset controller:
        controller.instance_variable_set(:@actor, nil)

        post :update, id: generic_file, revision: 'content.0'

        restored_file = generic_file.reload
        version3 = restored_file.content.latest_version
        expect(version3.versionID).not_to eq(version2.versionID)
        expect(version3.versionID).not_to eq(version1.versionID)
        expect(restored_file.content.version_committer(version3)).to eq(user.user_key)
      end
    end

    it "should add new groups and users" do
      post :update, id: generic_file, generic_file: { tag: [''], permissions:
        { new_group_name: { 'group1' => 'read' }, new_user_name: { 'user1' => 'edit' }}}

      expect(assigns[:generic_file].read_groups).to eq(["group1"])
      expect(assigns[:generic_file].edit_users).to include("user1", @user.user_key)
    end
    it "should update existing groups and users" do
      generic_file.read_groups = ['group3']
      generic_file.save
      post :update, id: generic_file, generic_file: { tag: [''], permissions:
        { new_group_name: '', new_group_permission: '', new_user_name: '', new_user_permission: '', group: { 'group3' => 'read' }}}

      expect(assigns[:generic_file].read_groups).to eq(["group3"])
    end

    it "spawns a virus check" do
      s1 = double('one')
      allow(ContentNewVersionEventJob).to receive(:new).with(generic_file.pid, 'jilluser@example.com').and_return(s1)
      expect(Sufia.queue).to receive(:push).with(s1).once

      s2 = double('one')
      allow(CharacterizeJob).to receive(:new).with(generic_file.pid).and_return(s2)
      allow(CreateDerivativesJob).to receive(:new).with(generic_file.pid).and_return(s2)
      @user = FactoryGirl.find_or_create(:jill)
      sign_in @user
      file = fixture_file_upload('/world.png', 'image/png')
      expect(Sufia::GenericFile::Actor).to receive(:virus_check).and_return(0)
      expect(Sufia.queue).to receive(:push).with(s2).once
      post :update, id: generic_file.pid, filedata: file, 'Filename' => 'The world', generic_file: { tag: [''], permissions: { new_user_name: { archivist1: 'edit' } } }
    end

    context "when there's an error saving" do
      let!(:generic_file) do
        GenericFile.new.tap do |gf|
          gf.apply_depositor_metadata(@user)
          gf.save!
        end
      end
      it "redirects to edit" do
        expect_any_instance_of(GenericFile).to receive(:valid?).and_return(false)
        post :update, id: generic_file, generic_file: {:tag=>['']}
        expect(response).to be_successful
        expect(response).to render_template('edit')
        expect(assigns[:generic_file]).to eq generic_file
      end
    end
  end

  describe "someone elses files" do
    before do
      f = GenericFile.new(pid: 'test5')
      f.apply_depositor_metadata('archivist1@example.com')
      f.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      # grant public read access explicitly
      f.read_groups = ['public']
      f.save
      @file = f
      allow_any_instance_of(Sufia::GenericFile::Actor).to receive(:push_characterize_job)
    end
    after do
      GenericFile.find('test5').destroy
    end
    describe "edit" do
      it "should give me a flash error" do
        get :edit, id: "test5"
        expect(response).to redirect_to @routes.url_helpers.generic_file_path('test5')
        expect(flash[:alert]).not_to be_nil
        expect(flash[:alert]).not_to be_empty
        expect(flash[:alert]).to include("You do not have sufficient privileges to edit this document")
      end
    end
    describe "view" do
      it "should show me the file" do
        get :show, id: "test5"
        expect(response).not_to redirect_to(action: 'show')
        expect(flash[:alert]).to be_nil
      end
      it "should set the breadcrumbs" do
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
        get :show, id: "test5"
      end
    end
    describe "flash" do
      it "should not let the user submit if they logout" do
        sign_out @user
        get :new
        expect(response).not_to be_success
        expect(flash[:alert]).not_to be_nil
        expect(flash[:alert]).to include("You need to sign in or sign up before continuing")
      end
      it "should filter flash if they signin" do
        sign_in @user
        get :show, id: "test5"
        expect(flash[:alert]).to be_nil
      end
      describe "failing audit" do
        before do
          allow_any_instance_of(ActiveFedora::RelsExtDatastream).to receive(:dsChecksumValid).and_return(false)
          @archivist = FactoryGirl.find_or_create(:archivist)
        end
        it "should display failing audits" do
          sign_in @archivist
          AuditJob.new(@file.pid, "RELS-EXT", @file.rels_ext.versionID).run
          get :show, id: "test5"
          expect(assigns[:notify_number]).to eq(1)
          expect(@archivist.mailbox.inbox[0].messages[0].subject).to eq("Failing Audit Run")
        end
      end
    end
  end
end
