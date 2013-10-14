require 'spec_helper'

describe GenericFilesController do
  before do
    controller.stub(:has_access?).and_return(true)

    @user = FactoryGirl.find_or_create(:user)
    sign_in @user
    User.any_instance.stub(:groups).and_return([])
    controller.stub(:clear_session_user) ## Don't clear out the authenticated session
  end
  describe "#create" do
    before do
      @file_count = GenericFile.count
      @mock = GenericFile.new({:pid => 'test:123'})
      GenericFile.stub(:new).and_return(@mock)
    end
    after do
      GenericFile.unstub(:new)
      begin
        Batch.find("sample:batch_id").delete
      rescue
      end
      @mock.delete unless @mock.inner_object.class == ActiveFedora::UnsavedDigitalObject
    end

    it "should render error the file wasn't actually a file" do
      file = 'hello'
      xhr :post, :create, :files=>[file], :Filename=>"The World", :batch_id=>'sample:batch_id', :permission=>{"group"=>{"public"=>"read"} }, :terms_of_service => '1'
      response.status.should == 422
      JSON.parse(response.body).first['error'].should match(/no file for upload/i)
    end



    it "should spawn a content deposit event job" do
      file = fixture_file_upload('/world.png','image/png')
      s1 = double('one')
      ContentDepositEventJob.should_receive(:new).with('test:123', 'jilluser@example.com').and_return(s1)
      Sufia.queue.should_receive(:push).with(s1).once

      s2 = double('one')
      CharacterizeJob.should_receive(:new).with('test:123').and_return(s2)
      Sufia.queue.should_receive(:push).with(s2).once
      xhr :post, :create, :files=>[file], :Filename=>"The world", :batch_id => "sample:batch_id", :permission=>{"group"=>{"public"=>"read"} }, :terms_of_service => '1'
    end

    it "should expand zip files" do
      file = fixture_file_upload('/icons.zip','application/zip')
      s1 = double('one')
      ContentDepositEventJob.should_receive(:new).with('test:123', 'jilluser@example.com').and_return(s1)
      Sufia.queue.should_receive(:push).with(s1).once

      s2 = double('one')
      CharacterizeJob.should_receive(:new).with('test:123').and_return(s2)
      Sufia.queue.should_receive(:push).with(s2).once

      s3 = double('one')
      UnzipJob.should_receive(:new).with('test:123').and_return(s3)
      Sufia.queue.should_receive(:push).with(s3).once

      xhr :post, :create, :files=>[file], :Filename=>"The world", :batch_id => "sample:batch_id", :permission=>{"group"=>{"public"=>"read"} }, :terms_of_service => '1'
    end

    it "should download and import a file from a given url" do
      pending "This is just downloading a 401 error page"
      date_today = Date.today
      Date.stub(:today).and_return(date_today)
      generic_file = GenericFile.new      #find(self.pid)
      Sufia::GenericFile::Actions.create_metadata(generic_file, @user, '1234')
      #generic_file.import_url = "https://dl.dropboxusercontent.com/1/view/kcb4j1dtkw0td3z/ArticleCritique.doc"
      generic_file.import_url =  "https://dl.dropboxusercontent.com/1/view/m4og1xrgbk3ihw6/Getting%20Started.pdf"
      generic_file.save
      f = Tempfile.new(generic_file.pid)  #self.pid)
      f.binmode
      # download file from url
      uri = URI(generic_file.import_url)
      http = Net::HTTP.new(uri.host, uri.port) 
      http.use_ssl = uri.scheme == "https"  # enable SSL/TLS
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      http.start do  
        http.request_get(uri.to_s) do |resp|
          resp.read_body do |segment|
            f.write(segment)
          end 
        end 
      end 
      job_user = User.batchuser()
      user = User.find_by_user_key(generic_file.depositor)
      # check for virus
      if Sufia::GenericFile::Actions.virus_check(f) != 0
        message = "The file (#{File.basename(uri.path)}) was unable to be imported because it contained a virus."
        job_user.send_message(user, message, 'File Import Error') 
        return
      end 
      f.rewind
      # attach downloaded file to generic file stubbed out
      Sufia::GenericFile::Actions.create_content(generic_file, f, File.basename(uri.path), 'content', user)
    end

    it "should create and save a file asset from the given params" do
      date_today = Date.today
      Date.stub(:today).and_return(date_today)
      file = fixture_file_upload('/world.png','image/png')
      xhr :post, :create, :files=>[file], :Filename=>"The world", :batch_id => "sample:batch_id", :permission=>{"group"=>{"public"=>"read"} }, :terms_of_service => '1'
      response.should be_success
      GenericFile.count.should == @file_count + 1

      saved_file = GenericFile.find('test:123')

      # This is confirming that the correct file was attached
      saved_file.label.should == 'world.png'
      saved_file.content.checksum.should == 'f794b23c0c6fe1083d0ca8b58261a078cd968967'
      saved_file.content.dsChecksumValid.should be_true

      # Confirming that date_uploaded and date_modified were set
      saved_file.date_uploaded.should == date_today
      saved_file.date_modified.should == date_today
    end

    it "should record what user created the first version of content" do
      #GenericFile.any_instance.stub(:to_solr).and_return({})
      file = fixture_file_upload('/world.png','image/png')
      xhr :post, :create, :files=>[file], :Filename=>"The world", :terms_of_service=>"1"

      saved_file = GenericFile.find('test:123')
      version = saved_file.content.latest_version
      version.versionID.should == "content.0"
      saved_file.content.version_committer(version).should == @user.user_key
    end

    it "should create batch associations from batch_id" do
      Sufia.config.stub(:id_namespace).and_return('sample')
      file = fixture_file_upload('/world.png','image/png')
      controller.stub(:add_posted_blob_to_asset)
      xhr :post, :create, :files=>[file], :Filename=>"The world", :batch_id => "sample:batch_id", :permission=>{"group"=>{"public"=>"read"} }, :terms_of_service=>"1"
      lambda {Batch.find("sample:batch_id")}.should raise_error(ActiveFedora::ObjectNotFoundError) # The controller shouldn't actually save the Batch, but it should write the batch id to the files.
      b = Batch.create(pid: "sample:batch_id")
      b.generic_files.first.pid.should == "test:123"
    end
    it "should set the depositor id" do
      file = fixture_file_upload('/world.png','image/png')
      xhr :post, :create, :files => [file], :Filename => "The world", :batch_id => "sample:batch_id", :permission => {"group"=>{"public"=>"read"} }, :terms_of_service => "1"
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
    it "Should call virus check" do
      controller.should_receive(:virus_check).and_return(0)      
      file = fixture_file_upload('/world.png','image/png')

      s1 = double('one')
      ContentDepositEventJob.should_receive(:new).with('test:123', 'jilluser@example.com').and_return(s1)
      Sufia.queue.should_receive(:push).with(s1).once

      s2 = double('one')
      CharacterizeJob.should_receive(:new).with('test:123').and_return(s2)
      Sufia.queue.should_receive(:push).with(s2).once
      xhr :post, :create, :files=>[file], :Filename=>"The world", :batch_id => "sample:batch_id", :permission=>{"group"=>{"public"=>"read"} }, :terms_of_service=>"1"
    end
    
    it "should error out of create and save after on continuos rsolr error" do
      GenericFile.any_instance.stub(:save).and_raise(RSolr::Error::Http.new({},{}))  
          
      file = fixture_file_upload('/world.png','image/png')
      xhr :post, :create, :files=>[file], :Filename=>"The world", :batch_id => "sample:batch_id", :permission=>{"group"=>{"public"=>"read"} }, :terms_of_service=>"1"
      response.body.should include("Error occurred while creating generic file.")
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
        File.exist?("#{@mock_upload_directory}/image.jpg").should be_false
        File.exist?("#{@mock_upload_directory}/world.png").should be_false
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
        File.exist?("#{@mock_upload_directory}/world.png").should be_false
        # And into the storage directory
        files = GenericFile.find(Solrizer.solr_name("is_part_of",:symbol) => 'info:fedora/sufia:xw42n7934')
        files.first.label.should == 'world.png'
      end
      it "should ingest directories from the filesystem" do
        lambda { post :create, local_file: ["world.png", "import"], batch_id: "xw42n7934"}.should change(GenericFile, :count).by(4)
        response.should redirect_to Sufia::Engine.routes.url_helpers.batch_edit_path('xw42n7934')
        # These files should have been moved out of the upload directory
        File.exist?("#{@mock_upload_directory}/import/files/Example.ogg").should be_false
        File.exist?("#{@mock_upload_directory}/import/files/icons.zip").should be_false
        File.exist?("#{@mock_upload_directory}/import/metadata/dublin_core_rdf_descMetadata.nt").should be_false
        File.exist?("#{@mock_upload_directory}/world.png").should be_false
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
  
  describe "#virus_check" do
    it "passing virus check should not create flash error" do
      GenericFile.any_instance.stub(:to_solr).and_return({})
      file = fixture_file_upload('/world.png','image/png')  
      Sufia::GenericFile::Actions.should_receive(:virus_check).with(file).and_return(0)    
      controller.send :virus_check, file
      flash[:error].should be_nil
    end
    it "failing virus check should create flash" do
      GenericFile.any_instance.stub(:to_solr).and_return({})
      file = fixture_file_upload('/world.png','image/png')  
      Sufia::GenericFile::Actions.should_receive(:virus_check).with(file).and_return(1)    
      controller.send :virus_check, file
      flash[:error].should_not be_empty
    end
  end

  describe "audit" do
    before do
      #GenericFile.any_instance.stub(:to_solr).and_return({})
      @generic_file = GenericFile.new
      @generic_file.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      @generic_file.apply_depositor_metadata('mjg36')
      @generic_file.save
    end
    after do
      @generic_file.delete
    end
    it "should return json with the result" do
      xhr :post, :audit, :id=>@generic_file.pid
      response.should be_success
      lambda { JSON.parse(response.body) }.should_not raise_error
      audit_results = JSON.parse(response.body).collect { |result| result["pass"] }
      audit_results.reduce(true) { |sum, value| sum && value }.should be_true
    end
  end

  describe "destroy" do
    before(:each) do
      @generic_file = GenericFile.new
      @generic_file.apply_depositor_metadata(@user)
      @generic_file.save
      @user = FactoryGirl.find_or_create(:user)
      sign_in @user
    end
    after do
      @user.delete
    end    
    it "should delete the file" do
      GenericFile.find(@generic_file.pid).should_not be_nil
      delete :destroy, :id=>@generic_file.pid
      lambda { GenericFile.find(@generic_file.pid) }.should raise_error(ActiveFedora::ObjectNotFoundError)
    end
    it "should spawn a content delete event job" do
      s1 = double('one')
      ContentDeleteEventJob.should_receive(:new).with(@generic_file.noid, @user.user_key).and_return(s1)
      Sufia.queue.should_receive(:push).with(s1).once
      delete :destroy, :id=>@generic_file.pid
    end
  end

  describe "update" do
    before do
      #controller.should_receive(:virus_check).and_return(0)      
      @generic_file = GenericFile.new
      @generic_file.apply_depositor_metadata(@user)
      @generic_file.save
    end
    after do
      @generic_file.delete
    end

    it "should spawn a content update event job" do
      s1 = double('one')
      ContentUpdateEventJob.should_receive(:new).with(@generic_file.pid, 'jilluser@example.com').and_return(s1)
      Sufia.queue.should_receive(:push).with(s1).once
      @user = FactoryGirl.find_or_create(:user)
      sign_in @user
      post :update, :id=>@generic_file.pid, :generic_file=>{:title=>'new_title', :tag=>[''], :permissions=>{:new_user_name=>{'archivist1'=>'edit'}}}
      @user.delete      
    end

    it "should spawn a content new version event job" do
      s1 = double('one')
      ContentNewVersionEventJob.should_receive(:new).with(@generic_file.pid, 'jilluser@example.com').and_return(s1)
      Sufia.queue.should_receive(:push).with(s1).once
      s2 = double('one')
      CharacterizeJob.should_receive(:new).with(@generic_file.pid).and_return(s2)
      Sufia.queue.should_receive(:push).with(s2).once
      @user = FactoryGirl.find_or_create(:user)
      sign_in @user

      file = fixture_file_upload('/world.png','image/png')
      post :update, :id=>@generic_file.pid, :filedata=>file, :Filename=>"The world", :generic_file=>{:tag=>[''],  :permissions=>{:new_user_name=>{'archivist1'=>'edit'}}}
      @user.delete
    end

    it "should change mime type when restoring a revision with a different mime type" do
      @user = FactoryGirl.find_or_create(:user)
      sign_in @user

      file = fixture_file_upload('/world.png','image/png')
      post :update, :id=>@generic_file.pid, :filedata=>file, :Filename=>"The world", :generic_file=>{:tag=>[''],  :permissions=>{:new_user_name=>{'archivist1@example.com'=>'edit'}}}

      posted_file = GenericFile.find(@generic_file.pid)
      version1 = posted_file.content.latest_version
      posted_file.content.version_committer(version1).should == @user.user_key

      file = fixture_file_upload('/image.jpg','image/jpg')
      post :update, :id=>@generic_file.pid, :filedata=>file, :Filename=>"The world", :generic_file=>{:tag=>[''],  :permissions=>{:new_user_name=>{'archivist1@example.com'=>'edit'}}}

      posted_file = GenericFile.find(@generic_file.pid)
      version2 = posted_file.content.latest_version
      posted_file.content.version_committer(version2).should == @user.user_key

      posted_file.content.mimeType.should == "image/jpeg"
      post :update, :id=>@generic_file.pid, :revision=>'content.0'


      restored_file = GenericFile.find(@generic_file.pid)
      version3 = restored_file.content.latest_version
      version3.versionID.should_not == version2.versionID
      version3.versionID.should_not == version1.versionID
      restored_file.content.version_committer(version3).should == @user.user_key
      restored_file.content.mimeType.should == "image/png"
      @user.delete
    end


    it "should record what user added a new version" do
      @user = FactoryGirl.find_or_create(:user)
      sign_in @user

      file = fixture_file_upload('/world.png','image/png')
      post :update, :id=>@generic_file.pid, :filedata=>file, :Filename=>"The world", :generic_file=>{:tag=>[''],  :permissions=>{:new_user_name=>{'archivist1@example.com'=>'edit'}}}

      posted_file = GenericFile.find(@generic_file.pid)
      version1 = posted_file.content.latest_version
      posted_file.content.version_committer(version1).should == @user.user_key

      # other user uploads new version 
      # TODO this should be a separate test
      archivist = FactoryGirl.find_or_create(:archivist)
      controller.stub(:current_user).and_return(archivist)

      ContentUpdateEventJob.should_receive(:new).with(@generic_file.pid, 'jilluser@example.com').never

      s1 = double('one')
      ContentNewVersionEventJob.should_receive(:new).with(@generic_file.pid, archivist.user_key).and_return(s1)
      Sufia.queue.should_receive(:push).with(s1).once

      s2 = double('one')
      CharacterizeJob.should_receive(:new).with(@generic_file.pid).and_return(s2)
      Sufia.queue.should_receive(:push).with(s2).once
      file = fixture_file_upload('/image.jpg','image/jpg')
      post :update, :id=>@generic_file.pid, :filedata=>file, :Filename=>"The world"

      edited_file = GenericFile.find(@generic_file.pid)
      version2 = edited_file.content.latest_version
      version2.versionID.should_not == version1.versionID
      edited_file.content.version_committer(version2).should == archivist.user_key

      # original user restores his or her version
      controller.stub(:current_user).and_return(@user)
      sign_in @user
      ContentUpdateEventJob.should_receive(:new).with(@generic_file.pid, 'jilluser@example.com').never
      s1 = double('one')
      ContentRestoredVersionEventJob.should_receive(:new).with(@generic_file.pid, @user.user_key, 'content.0').and_return(s1)
      Sufia.queue.should_receive(:push).with(s1).once

      s2 = double('one')
      CharacterizeJob.should_receive(:new).with(@generic_file.pid).and_return(s2)
      Sufia.queue.should_receive(:push).with(s2).once
      post :update, :id=>@generic_file.pid, :revision=>'content.0'

      restored_file = GenericFile.find(@generic_file.pid)
      version3 = restored_file.content.latest_version
      version3.versionID.should_not == version2.versionID
      version3.versionID.should_not == version1.versionID
      restored_file.content.version_committer(version3).should == @user.user_key
      @user.delete
    end

    it "should add a new groups and users" do
      post :update, :id=>@generic_file.pid, :generic_file=>{:tag=>[''], :permissions=>{:new_group_name=>{'group1'=>'read'}, :new_user_name=>{'user1'=>'edit'}}}

      assigns[:generic_file].read_groups.should == ["group1"]
      assigns[:generic_file].edit_users.should include("user1", @user.user_key)
    end
    it "should update existing groups and users" do
      @generic_file.read_groups = ['group3']
      @generic_file.save
      post :update, :id=>@generic_file.pid, :generic_file=>{:tag=>[''], :permissions=>{:new_group_name=>'', :new_group_permission=>'', :new_user_name=>'', :new_user_permission=>'', :group=>{'group3' =>'read'}}}

      assigns[:generic_file].read_groups.should == ["group3"]
    end
    it "should spawn a virus check" do
      # The expectation is in the begin block
      controller.should_receive(:virus_check).and_return(0)      
      s1 = double('one')
      ContentNewVersionEventJob.should_receive(:new).with(@generic_file.pid, 'jilluser@example.com').and_return(s1)
      Sufia.queue.should_receive(:push).with(s1).once

      s2 = double('one')
      CharacterizeJob.should_receive(:new).with(@generic_file.pid).and_return(s2)
      Sufia.queue.should_receive(:push).with(s2).once
      GenericFile.stub(:save).and_return({})
      @user = FactoryGirl.find_or_create(:user)
      sign_in @user
      file = fixture_file_upload('/world.png','image/png')
      post :update, :id=>@generic_file.pid, :filedata=>file, :Filename=>"The world", :generic_file=>{:tag=>[''],  :permissions=>{:new_user_name=>{'archivist1'=>'edit'}}}
    end

    it "should go back to edit on an error" do
      GenericFile.any_instance.should_receive(:valid?).and_return(false)
      post :update, :id=>@generic_file.pid, :generic_file=>{:tag=>['']}
      response.should be_successful 
      response.should render_template('edit')
      assigns[:generic_file].should == @generic_file
    end

  end

  describe "someone elses files" do
    before do
      f = GenericFile.new(:pid => 'sufia:test5')
      f.apply_depositor_metadata('archivist1@example.com')
      f.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      # grant public read access explicitly
      f.read_groups = ['public']
      f.should_receive(:characterize_if_changed).and_yield
      f.save
      @file = f
    end
    after do
      GenericFile.find('sufia:test5').destroy
    end
    describe "edit" do
      it "should give me a flash error" do
        get :edit, id:"test5"
        response.should redirect_to @routes.url_helpers.generic_file_path('test5')
        flash[:alert].should_not be_nil
        flash[:alert].should_not be_empty
        flash[:alert].should include("You do not have sufficient privileges to edit this document")
      end
    end
    describe "view" do
      it "should show me the file" do
        get :show, id:"test5"
        response.should_not redirect_to(:action => 'show')
        flash[:alert].should be_nil
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
        get :show, id:"test5"
        flash[:alert].should be_nil
      end
      describe "failing audit" do
        render_views
        before do
          ActiveFedora::RelsExtDatastream.any_instance.stub(:dsChecksumValid).and_return(false)
          @archivist = FactoryGirl.find_or_create(:archivist)
        end
        it "should display failing audits" do
          sign_in @archivist
          @ds = @file.datastreams.first
          AuditJob.new(@file.pid, @ds[0], @ds[1].versionID).run
          get :show, id:"test5"
          assigns[:notify_number].should == 1
          response.body.should include('<span id="notify_number" class="overlay"> 1</span>') # notify should be 1 for failing job
          @archivist.mailbox.inbox[0].messages[0].subject.should == "Failing Audit Run"
        end
      end
    end
  end
end
