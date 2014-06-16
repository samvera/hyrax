require 'spec_helper'

describe CurationConcern::GenericFilesController do
  let(:user) { FactoryGirl.create(:user) }
  let(:file) { fixture_file_upload('files/image.png','image/png') }
  let(:parent) { FactoryGirl.create(:generic_work, edit_users: [user.user_key], visibility:Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC) }

  context "when signed in" do
    before { sign_in user }

    describe "#create" do
      before do
        Worthwhile::GenericFile.destroy_all
        allow(Worthwhile::GenericFile).to receive(:new).and_return(Worthwhile::GenericFile.new(pid: 'test:123'))
      end

      context "on the happy path" do
        let(:date_today) { Date.today }

        before do
          allow(Date).to receive(:today).and_return(date_today)
        end

        it "spawns a CharacterizeJob" do
          s2 = double('one')
          expect(CharacterizeJob).to receive(:new).with('test:123').and_return(s2)
          expect(Sufia.queue).to receive(:push).with(s2).once
          expect {
            xhr :post, :create, files: [file], parent_id: parent,
                 permission: { group: { 'public' => 'read' } }
            expect(response).to be_success
          }.to change { Worthwhile::GenericFile.count }.by(1)
          expect(flash[:error]).to be_nil
          saved_file = assigns[:generic_file].reload

          expect(saved_file.label).to eq 'image.png'
          expect(saved_file.batch).to eq parent

          # Confirming that date_uploaded and date_modified were set
          expect(saved_file.date_uploaded).to eq date_today
          expect(saved_file.date_modified).to eq date_today
          expect(saved_file.depositor).to eq user.email
          version = saved_file.content.latest_version
          expect(version.versionID).to eq "content.0"
          expect(saved_file.content.version_committer(version)).to eq user.email
        end

        it "copies visibility from the parent" do
          s2 = double('one')
          expect(CharacterizeJob).to receive(:new).with('test:123').and_return(s2)
          expect(Sufia.queue).to receive(:push).with(s2).once
          xhr :post, :create, files: [file], parent_id: parent
          expect(assigns[:generic_file]).to be_persisted
          saved_file = assigns[:generic_file].reload
          expect(saved_file.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        end
      end

      context "on something that isn't a file" do
        it "should render error" do
          xhr :post, :create, files: ['hello'], parent_id: parent,
               permission: { group: { 'public' => 'read' } }, terms_of_service: '1'
          expect(response.status).to eq 422
          err = JSON.parse(response.body).first['error']
          expect(err).to match(/no file for upload/i)
        end
      end

      context "when the file has a virus" do
        it "displays a flash error" do
          skip
          expect(Sufia::GenericFile::Actions).to receive(:virus_check).with(file.path).and_raise(Sufia::VirusFoundError.new('A virus was found'))
          xhr :post, :create, files: [file], parent_id: parent,
               permission: { group: { 'public' => 'read' } }, terms_of_service: '1'
          expect(flash[:error]).to include('A virus was found')
        end
      end

      context "when solr is down" do
        it "should error out of create and save after on continuos rsolr error" do
          allow_any_instance_of(Worthwhile::GenericFile).to receive(:save).and_raise(RSolr::Error::Http.new({},{}))

          xhr :post, :create, files: [file], parent_id: parent,
               permission: { group: { 'public' => 'read' } }, terms_of_service: '1'
          expect(response.body).to include("Error occurred while creating generic file.")
        end
      end

    end

    describe "destroy" do
      let(:generic_file) do
        Worthwhile::GenericFile.new.tap do |gf|
          gf.apply_depositor_metadata(user)
          gf.batch = parent
          gf.save!
        end
      end

      it "should delete the file" do
        expect(Worthwhile::GenericFile.find(generic_file.pid)).to be_kind_of Worthwhile::GenericFile
        delete :destroy, id: generic_file
        expect { Worthwhile::GenericFile.find(generic_file.pid) }.to raise_error ActiveFedora::ObjectNotFoundError
        expect(response).to redirect_to [:curation_concern, parent]
      end
    end

    describe "update" do
      let!(:generic_file) do
        Worthwhile::GenericFile.new.tap do |gf|
          gf.apply_depositor_metadata(user)
          gf.batch = parent
          gf.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
          gf.save!
        end
      end

      after do
        generic_file.destroy
      end

      context "updating metadata" do
        it "should be successful" do
          post :update, id: generic_file, generic_file: 
            {title: 'new_title', tag: [''], permissions: { new_user_name: {'archivist1'=>'edit'}}}
          expect(response).to redirect_to [:curation_concern, generic_file]
        end

        it "should go back to edit on an error" do
          allow_any_instance_of(Worthwhile::GenericFile).to receive(:valid?).and_return(false)
          post :update, id: generic_file, generic_file: 
            {title: 'new_title', tag: [''], permissions: { new_user_name: {'archivist1'=>'edit'}}}
          expect(response).to be_successful
          expect(response).to render_template('edit')
          expect(assigns[:generic_file]).to eq generic_file
        end

        it "should add a new groups and users" do
          skip
          post :update, id: generic_file, generic_file: 
            { title: 'new_title', tag: [''], permissions: { new_group_name: {'group1'=>'read'}, new_user_name: {'user1'=>'edit'}}}

          expect(assigns[:generic_file].read_groups).to eq ["group1"]
          expect(assigns[:generic_file].edit_users).to include("user1", @user.user_key)
        end

        it "should update existing groups and users" do
          skip
          generic_file.read_groups = ['group3']
          generic_file.save! # TODO slow test, more than one save.
          post :update, id: generic_file, generic_file: 
            { title: 'new_title', tag: [''], permissions: { new_group_name: '', new_user_name: '', group: {'group3' => 'read' }}}
          expect(assigns[:generic_file].read_groups).to eq ["group3"]
        end

        it "should update visibility" do
          new_visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          post :update, id: generic_file, generic_file: {visibility: new_visibility, embargo_release_date:""}
          expect(generic_file.reload.visibility).to eq new_visibility
        end
      end

      context "updating file content" do
        it "should be successful" do
          s2 = double('one')
          expect(CharacterizeJob).to receive(:new).with(generic_file.pid).and_return(s2)
          expect(Sufia.queue).to receive(:push).with(s2).once
          post :update, id: generic_file, file: file
          expect(response).to redirect_to [:curation_concern, generic_file]
          expect(generic_file.reload.label).to eq 'image.png'
        end
      end
 
      context "restoring an old version" do
        before do
          allow(Sufia.queue).to receive(:push) # don't run characterization jobs
          # Create version 0
          generic_file.add_file('test123', 'content', 'file.txt')
          generic_file.save!

          # Create version 1
          generic_file.add_file('<xml>This is version 2</xml>', 'content', 'md.xml')
          generic_file.save!
        end

        it "should be successful" do
          post :update, id: generic_file, revision: 'content.0'
          expect(response).to redirect_to [:curation_concern, generic_file]
          reloaded = generic_file.reload.content
          expect(reloaded.latest_version.versionID).to eq 'content.2'
          expect(reloaded.content).to eq 'test123'
          expect(reloaded.mimeType).to eq 'text/plain'
        end
      end
    end
  end

  context "someone elses files" do
    let(:generic_file) do
      Worthwhile::GenericFile.new.tap do |gf|
        gf.apply_depositor_metadata('archivist1@example.com')
        gf.read_groups = ['public']
        gf.batch = parent
        gf.save!
      end
    end
    after do
      # GenericFile.find('sufia:test5').destroy
    end
    describe "edit" do
      it "should give me a flash error" do
        get :edit, id: generic_file
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end
    describe "view" do
      it "should show me the file" do
        get :show, id: generic_file
        expect(response).to be_success
      end
    end
    it "should not let the user submit if they logout" do
      get :new, parent_id: parent
      expect(response).to redirect_to root_path
      expect(flash[:alert]).to eq "You are not authorized to access this page."
    end
  end
end
