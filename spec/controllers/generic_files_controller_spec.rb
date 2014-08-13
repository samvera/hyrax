require 'spec_helper'

describe GenericFilesController do
  before do
    controller.stub(:has_access?).and_return(true)
    @user = FactoryGirl.find_or_create(:jill)
    sign_in @user
    User.any_instance.stub(:groups).and_return([])
    controller.stub(:clear_session_user) ## Don't clear out the authenticated session
  end

  describe "#create" do
    before do
      @file_count = GenericFile.count
      @mock = GenericFile.new({pid: 'test:123'})
      GenericFile.stub(:new).and_return(@mock)
    end

    after do
      begin
        GenericFile.unstub(:new)
      rescue RSpec::Mocks::MockExpectationError => e
      end
      Batch.find("sample:batch_id").delete rescue
      @mock.delete unless @mock.inner_object.class == ActiveFedora::UnsavedDigitalObject
    end

    it "should render error the file wasn't actually a file" do
      file = 'hello'
      xhr :post, :create, files: [file], Filename: "The World", batch_id: 'sample:batch_id', permission: {"group"=>{"public"=>"read"} }, terms_of_service: '1'
      response.status.should == 422
      JSON.parse(response.body).first['error'].should match(/no file for upload/i)
    end

    it "spawns a content deposit event job" do
      file = fixture_file_upload('/world.png','image/png')
      s1 = double('one')
      allow(ContentDepositEventJob).to receive(:new).with('test:123', 'jilluser@example.com').and_return(s1)
      expect(Sufia.queue).to receive(:push).with(s1).once

      s2 = double('one')
      allow(CharacterizeJob).to receive(:new).with('test:123').and_return(s2)
      expect(Sufia.queue).to receive(:push).with(s2).once
      xhr :post, :create, files: [file], 'Filename' => 'The world', batch_id: 'sample:batch_id', permission: {group: { public: 'read' } }, terms_of_service: '1'
      expect(flash[:error]).to be_nil
    end

    it "displays a flash error when file has a virus" do
      file = fixture_file_upload('/world.png', 'image/png')
      Sufia::GenericFile::Actor.should_receive(:virus_check).with(file.path).and_raise(Sufia::VirusFoundError.new('A virus was found'))
      xhr :post, :create, files: [file], Filename: "The world", batch_id: "sample:batch_id", permission: {"group"=>{"public"=>"read"} }, terms_of_service: '1'
      flash[:error].should_not be_blank
      flash[:error].should include('A virus was found')
    end

    it "should create and save a file asset from the given params" do
      date_today = Date.today
      Date.stub(:today).and_return(date_today)
      file = fixture_file_upload('/world.png','image/png')
      xhr :post, :create, files: [file], Filename: "The world", batch_id: "sample:batch_id", permission: {"group"=>{"public"=>"read"} }, terms_of_service: '1'
      response.should be_success
      GenericFile.count.should == @file_count + 1

      saved_file = GenericFile.find('test:123')

      # This is confirming that the correct file was attached
      saved_file.label.should == 'world.png'
      saved_file.content.checksum.should == 'f794b23c0c6fe1083d0ca8b58261a078cd968967'
      expect(saved_file.content.dsChecksumValid).to be true

      # Confirming that date_uploaded and date_modified were set
      saved_file.date_uploaded.should == date_today
      saved_file.date_modified.should == date_today
    end

    it "should record what user created the first version of content" do
      file = fixture_file_upload('/world.png','image/png')
      xhr :post, :create, files: [file], Filename: "The world", batch_id: "sample:batch_id", permission: {"group"=>{"public"=>"read"} }, terms_of_service: "1"
      saved_file = GenericFile.find('test:123')
      version = saved_file.content.latest_version
      version.versionID.should == "content.0"
      saved_file.content.version_committer(version).should == @user.user_key
    end

    it "should create batch associations from batch_id" do
      Sufia.config.stub(:id_namespace).and_return('sample')
      file = fixture_file_upload('/world.png','image/png')
      controller.stub(:add_posted_blob_to_asset)
      xhr :post, :create, files: [file], Filename: "The world", batch_id: "sample:batch_id", permission: {"group"=>{"public"=>"read"} }, terms_of_service: "1"
      GenericFile.unstub(:new)
      lambda {Batch.find("sample:batch_id")}.should raise_error(ActiveFedora::ObjectNotFoundError) # The controller shouldn't actually save the Batch, but it should write the batch id to the files.
      batch = Batch.create(pid: "sample:batch_id")
      batch.generic_files.first.pid.should == "test:123"
    end
    it "should set the depositor id" do
      file = fixture_file_upload('/world.png','image/png')
      xhr :post, :create, files: [file], Filename: "The world", batch_id: "sample:batch_id", permission: {"group"=>{"public"=>"read"} }, terms_of_service: "1"
      response.should be_success

      saved_file = GenericFile.find('test:123')
      # This is confirming that apply_depositor_metadata recorded the depositor
      #TODO make sure this is moved to scholarsphere:
      #saved_file.properties.depositor.should == ['jilluser']
      saved_file.properties.depositor.should == ['jilluser@example.com']
      #TODO make sure this is moved to scholarsphere:
      #saved_file.depositor.should == 'jilluser'
      saved_file.depositor.should == 'jilluser@example.com'
      saved_file.properties.to_solr.keys.should include('depositor_tesim')
      #TODO make sure this is moved to scholarsphere:
      #saved_file.properties.to_solr['depositor_t'].should == ['jilluser']
      saved_file.properties.to_solr['depositor_tesim'].should == ['jilluser@example.com']
      saved_file.to_solr.keys.should include('depositor_tesim')
      saved_file.to_solr['depositor_tesim'].should == ['jilluser@example.com']
    end

    it "should error out of create and save after on continuos rsolr error" do
      GenericFile.any_instance.stub(:save).and_raise(RSolr::Error::Http.new({},{}))

      file = fixture_file_upload('/world.png','image/png')
      xhr :post, :create, files: [file], Filename: "The world", batch_id: "sample:batch_id", permission: {"group"=>{"public"=>"read"} }, terms_of_service: "1"
      response.body.should include("Error occurred while creating generic file.")
    end
  end

  describe "#create with browse-everything" do
    before do
      GenericFile.delete_all
      @json_from_browse_everything = {"0"=>{"url"=>"https://dl.dropbox.com/fake/blah-blah.filepicker-demo.txt.txt", "expires"=>"2014-03-31T20:37:36.214Z", "file_name"=>"filepicker-demo.txt.txt"}, "1"=>{"url"=>"https://dl.dropbox.com/fake/blah-blah.Getting%20Started.pdf", "expires"=>"2014-03-31T20:37:36.731Z", "file_name"=>"Getting+Started.pdf"}}
    end
    it "should ingest files from provide URLs" do
      ImportUrlJob.should_receive(:new).twice {"ImportJob"}
      Sufia.queue.should_receive(:push).with("ImportJob").twice
      expect { post :create, selected_files: @json_from_browse_everything, batch_id: "sample:batch_id" }.to change(GenericFile, :count).by(2)
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
      GenericFile.delete_all
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
      FileContentDatastream.any_instance.stub(:live?).and_return(true)
      GenericFile.destroy_all
    end
    context "when User model defines a directory path" do
      before do
        if $in_travis
          # In order to avoid an invalid derivative creation, just stub out the derivatives.
          GenericFile.any_instance.stub(:create_derivatives)
        end
        User.any_instance.stub(:directory).and_return(@mock_upload_directory)
      end
      it "should ingest files from the filesystem" do
        lambda { post :create, local_file: ["world.png", "image.jpg"], batch_id: "xw42n7934"}.should change(GenericFile, :count).by(2)
        response.should redirect_to Sufia::Engine.routes.url_helpers.batch_edit_path('xw42n7934')
        # These files should have been moved out of the upload directory
        expect(File).not_to exist("#{@mock_upload_directory}/image.jpg")
        expect(File).not_to exist("#{@mock_upload_directory}/world.png")
        # And into the storage directory
        files = GenericFile.find(Solrizer.solr_name("is_part_of",:symbol) => 'info:fedora/sufia:xw42n7934')
        files.first.label.should == 'world.png'
        files.last.label.should == 'image.jpg'
      end
      it "should ingest redirect to another location" do
        GenericFilesController.should_receive(:upload_complete_path).and_return(mock_url)
        lambda { post :create, local_file: ["world.png"], batch_id: "xw42n7934"}.should change(GenericFile, :count).by(1)
        response.should redirect_to mock_url
        # These files should have been moved out of the upload directory
        expect(File).not_to exist("#{@mock_upload_directory}/world.png")
        # And into the storage directory
        files = GenericFile.find(Solrizer.solr_name("is_part_of",:symbol) => 'info:fedora/sufia:xw42n7934')
        files.first.label.should == 'world.png'
      end
      it "should ingest directories from the filesystem" do
        lambda { post :create, local_file: ["world.png", "import"], batch_id: "xw42n7934"}.should change(GenericFile, :count).by(4)
        response.should redirect_to Sufia::Engine.routes.url_helpers.batch_edit_path('xw42n7934')
        # These files should have been moved out of the upload directory
        expect(File).not_to exist("#{@mock_upload_directory}/import/files/icons.zip")
        expect(File).not_to exist("#{@mock_upload_directory}/import/metadata/dublin_core_rdf_descMetadata.nt")
        expect(File).not_to exist("#{@mock_upload_directory}/world.png")
        # And into the storage directory
        files = GenericFile.find(Solrizer.solr_name("is_part_of",:symbol) => 'info:fedora/sufia:xw42n7934')
        files.first.label.should == 'world.png'
        ['icons.zip', 'Example.ogg'].each do |filename|
          files.select{|f| f.label == filename}.first.relative_path.should == "import/files/#{filename}"
        end
        files.select{|f| f.label == 'dublin_core_rdf_descMetadata.nt'}.first.relative_path.should == 'import/metadata/dublin_core_rdf_descMetadata.nt'
      end
    end
    context "when User model does not define directory path" do
      it "should return an error message and redirect to file upload page" do
        lambda { post :create, local_file: ["world.png", "image.jpg"], batch_id: "xw42n7934"}.should_not change(GenericFile, :count)
        response.should render_template :new
        flash[:alert].should == 'Your account is not configured for importing files from a user-directory on the server.'
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
    after do
      @generic_file.delete
    end
    it "should return json with the result" do
      xhr :post, :audit, id: @generic_file.pid
      response.should be_success
      lambda { JSON.parse(response.body) }.should_not raise_error
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
    after do
      @user.delete
    end
    it "should delete the file" do
      GenericFile.find(@generic_file.pid).should_not be_nil
      delete :destroy, id: @generic_file.pid
      lambda { GenericFile.find(@generic_file.pid) }.should raise_error(ActiveFedora::ObjectNotFoundError)
    end
    it "should spawn a content delete event job" do
      s1 = double('one')
      ContentDeleteEventJob.should_receive(:new).with(@generic_file.pid, @user.user_key).and_return(s1)
      Sufia.queue.should_receive(:push).with(s1).once
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
        sign_in @user
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
          OpenStruct.new(eventCategory: "Files", eventAction: "Downloaded", eventLabel: "sufia:123456789", totalEvents: "3")
        ])
        allow(download_query).to receive(:map).and_return(download_query.for_file.map(&:marshal_dump))
        allow(profile).to receive(:sufia__download).and_return(download_query)
      end

      it 'renders the stats view' do
        get :stats, id: @generic_file.noid
        expect(response).to be_success
        expect(response).to render_template(:stats)
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
      ContentUpdateEventJob.should_receive(:new).with(generic_file.pid, 'jilluser@example.com').and_return(s1)
      Sufia.queue.should_receive(:push).with(s1).once
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
      posted_file.content.version_committer(version1).should == @user.user_key

      file = fixture_file_upload('/image.jpg','image/jpg')
      post :update, id: generic_file, filedata: file, generic_file: { tag: [''], permissions: { new_user_name: { 'archivist1@example.com'=>'edit' } } }

      posted_file = GenericFile.find(generic_file.pid)
      version2 = posted_file.content.latest_version
      posted_file.content.version_committer(version2).should == @user.user_key

      posted_file.content.mimeType.should == "image/jpeg"
      post :update, id: generic_file, revision: 'content.0'

      restored_file = GenericFile.find(generic_file.pid)
      version3 = restored_file.content.latest_version
      version3.versionID.should_not == version2.versionID
      version3.versionID.should_not == version1.versionID
      restored_file.content.version_committer(version3).should == @user.user_key
      restored_file.content.mimeType.should == "image/png"
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

      assigns[:generic_file].read_groups.should == ["group1"]
      assigns[:generic_file].edit_users.should include("user1", @user.user_key)
    end
    it "should update existing groups and users" do
      generic_file.read_groups = ['group3']
      generic_file.save
      post :update, id: generic_file, generic_file: { tag: [''], permissions:
        { new_group_name: '', new_group_permission: '', new_user_name: '', new_user_permission: '', group: { 'group3' => 'read' }}}

      assigns[:generic_file].read_groups.should == ["group3"]
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
        GenericFile.any_instance.should_receive(:valid?).and_return(false)
        post :update, id: generic_file, generic_file: {:tag=>['']}
        response.should be_successful
        response.should render_template('edit')
        expect(assigns[:generic_file]).to eq generic_file
      end
    end
  end

  describe "someone elses files" do
    before do
      f = GenericFile.new(pid: 'sufia:test5')
      f.apply_depositor_metadata('archivist1@example.com')
      f.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      # grant public read access explicitly
      f.read_groups = ['public']
      f.save
      @file = f
      allow_any_instance_of(Sufia::GenericFile::Actor).to receive(:push_characterize_job)
    end
    after do
      GenericFile.find('sufia:test5').destroy
    end
    describe "edit" do
      it "should give me a flash error" do
        get :edit, id: "test5"
        response.should redirect_to @routes.url_helpers.generic_file_path('test5')
        flash[:alert].should_not be_nil
        flash[:alert].should_not be_empty
        flash[:alert].should include("You do not have sufficient privileges to edit this document")
      end
    end
    describe "view" do
      it "should show me the file" do
        get :show, id: "test5"
        response.should_not redirect_to(action: 'show')
        flash[:alert].should be_nil
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
        response.should_not be_success
        flash[:alert].should_not be_nil
        flash[:alert].should include("You need to sign in or sign up before continuing")
      end
      it "should filter flash if they signin" do
        sign_in @user
        get :show, id: "test5"
        flash[:alert].should be_nil
      end
      describe "failing audit" do
        before do
          ActiveFedora::RelsExtDatastream.any_instance.stub(:dsChecksumValid).and_return(false)
          @archivist = FactoryGirl.find_or_create(:archivist)
        end
        it "should display failing audits" do
          sign_in @archivist
          AuditJob.new(@file.pid, "RELS-EXT", @file.rels_ext.versionID).run
          get :show, id: "test5"
          assigns[:notify_number].should == 1
          @archivist.mailbox.inbox[0].messages[0].subject.should == "Failing Audit Run"
        end
      end
    end
  end
end
