require 'spec_helper'

describe CurationConcerns::GenericFilesController do
  let(:user) { FactoryGirl.create(:user) }
  let(:file) { fixture_file_upload('files/image.png','image/png') }
  let(:parent) { FactoryGirl.create(:generic_work, edit_users: [user.user_key], visibility:Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC) }

  context "when signed in" do
    before { sign_in user }

    describe "#create" do
      before do
        CurationConcerns::GenericFile.destroy_all
        allow(CurationConcerns::GenericFile).to receive(:new).and_return(CurationConcerns::GenericFile.new(id: '123'))
      end

      context "on the happy path" do
        let(:date_today) { DateTime.now }

        before do
          allow(Date).to receive(:today).and_return(date_today)
        end

        xit "spawns a CharacterizeJob" do
          s2 = double('one')
          expect(CharacterizeJob).to receive(:new).with('123').and_return(s2)
          expect(Sufia.queue).to receive(:push).with(s2).once
          expect {
            xhr :post, :create, files: [file], parent_id: parent,
              generic_file: { "title"=>[""], visibility_during_embargo: "restricted",
                              embargo_release_date: "2014-08-23",
                              visibility_after_embargo: "open", visibility_during_lease: "open",
                              lease_expiration_date: "2014-08-23",
                              visibility_after_lease: "restricted",
                              visibility: "restricted"}
            expect(response).to be_success
          }.to change { CurationConcerns::GenericFile.count }.by(1)
          expect(flash[:error]).to be_nil
          saved_file = assigns[:generic_file].reload

          expect(saved_file.label).to eq 'image.png'
          expect(saved_file.batch).to eq parent
          # Confirming that date_uploaded and date_modified were set
          # expect(saved_file.date_uploaded).to eq date_today
          expect(saved_file.date_modified).to eq date_today
          expect(saved_file.depositor).to eq user.email

          expect(saved_file.content.versions.count).to eq(3)
          expect(saved_file.content.latest_version).to be_instance_of(ActiveFedora::VersionsGraph::ResourceVersion)

          # Confirm that embargo/lease are not set.
          expect(saved_file).to_not be_under_embargo
          expect(saved_file).to_not be_active_lease
          # Presently it's coping from the parent and disregarding what is on the form.
          # expect(saved_file.visibility).to eq 'restricted'
          expect(saved_file.visibility).to eq 'open'
        end

        it "copies visibility from the parent" do
          s2 = double('one')
          expect(CharacterizeJob).to receive(:new).with('123').and_return(s2)
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
          allow_any_instance_of(CurationConcerns::GenericFile).to receive(:save).and_raise(RSolr::Error::Http.new({},{}))

          xhr :post, :create, files: [file], parent_id: parent,
               permission: { group: { 'public' => 'read' } }, terms_of_service: '1'
          expect(response.body).to include("Error occurred while creating generic file.")
        end
      end

    end

    describe "destroy" do
      let(:generic_file) do
        CurationConcerns::GenericFile.new.tap do |gf|
          gf.apply_depositor_metadata(user)
          gf.batch = parent
          gf.save!
        end
      end

      it "should delete the file" do
        expect(CurationConcerns::GenericFile.find(generic_file.id)).to be_kind_of CurationConcerns::GenericFile
        delete :destroy, id: generic_file
        expect { CurationConcerns::GenericFile.find(generic_file.id) }.to raise_error Ldp::Gone
        expect(response).to redirect_to main_app.curation_concerns_generic_work_path(parent)
      end
    end

    describe "update" do
      let!(:generic_file) do
        CurationConcerns::GenericFile.new.tap do |gf|
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
        it "should be successful and update attributes" do
          post :update, id: generic_file, generic_file:
            {title: ['new_title'], tag: [''], permissions_attributes: [{ type: 'person', name: 'archivist1', access: 'edit'}]}
          expect(response).to redirect_to main_app.curation_concerns_generic_file_path(generic_file)
          expect(assigns[:generic_file].title).to eq(['new_title'])
        end

        it "should go back to edit on an error" do
          allow_any_instance_of(CurationConcerns::GenericFile).to receive(:valid?).and_return(false)
          post :update, id: generic_file, generic_file:
            {title: ['new_title'], tag: [''], permissions_attributes: [{ type: 'person', name: 'archivist1', access: 'edit'}]}
          expect(response).to be_successful
          expect(response).to render_template('edit')
          expect(assigns[:generic_file]).to eq generic_file
        end

        it "should add a new groups and users" do
          skip
          post :update, id: generic_file, generic_file:
            { title: ['new_title'], tag: [''], permissions_attributes: [{ type: 'group', name: 'group1', access: 'read'}, { type: 'person', name: 'user1', access: 'edit'}]}

          expect(assigns[:generic_file].read_groups).to eq ["group1"]
          expect(assigns[:generic_file].edit_users).to include("user1", @user.user_key)
        end

        it "should update existing groups and users" do
          generic_file.read_groups = ['group3']
          generic_file.save! # TODO slow , more than one save.
          post :update, id: generic_file, generic_file:
            { title: ['new_title'], tag: [''], permissions_attributes:[{ type: 'group', name: 'group3', access: 'edit'}] }
          expect(assigns[:generic_file].edit_groups).to eq ["group3"]
        end

        context "updating visibility" do
          it "should apply public" do
            new_visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
            post :update, id: generic_file, generic_file: {visibility: new_visibility, embargo_release_date:""}
            expect(generic_file.reload.visibility).to eq new_visibility
          end

          it "should apply embargo" do
            post :update, id: generic_file, generic_file: {
              visibility: 'embargo',
              visibility_during_embargo: "restricted",
              embargo_release_date: "2099-09-05",
              visibility_after_embargo: "open",
              visibility_during_lease: "open",
              lease_expiration_date: "2099-09-05",
              visibility_after_lease: "restricted"
            }
            generic_file.reload
            expect(generic_file).to be_under_embargo
            expect(generic_file).to_not be_active_lease
          end
        end
      end

      context "updating file content" do
        it "should be successful" do
          s2 = double('one')
          expect(CharacterizeJob).to receive(:new).with(generic_file.id).and_return(s2)
          expect(Sufia.queue).to receive(:push).with(s2).once
          post :update, id: generic_file, files: [file]
          expect(response).to redirect_to main_app.curation_concerns_generic_file_path(generic_file)
          # expect(generic_file.reload.label).to eq 'image.png' # commented out because Characterization behavior is broken & will be replaced by Hydra::Works::File::Characterization
        end
      end

      context "restoring an old version" do
        before do
          allow(Sufia.queue).to receive(:push) # don't run characterization jobs
          # Create version 0
          generic_file.add_file('123', path: 'content', original_name: 'file.txt')
          generic_file.save!

          # Create version 1
          generic_file.add_file('<xml>This is version 2</xml>', path: 'content', original_name: 'md.xml')
          generic_file.save!
        end

        it "should be successful" do
          expect(generic_file.latest_version.label).to eq('version2')
          post :update, id: generic_file, revision: 'version1'
          expect(response).to redirect_to main_app.curation_concerns_generic_file_path(generic_file)
          reloaded = generic_file.reload.content
          expect(reloaded.latest_version.label).to eq 'version3'
          expect(reloaded.content).to eq '123'
          expect(reloaded.mime_type).to eq 'text/plain'
        end
      end
    end
  end

  context "someone elses files" do
    let(:generic_file) do
      CurationConcerns::GenericFile.new.tap do |gf|
        gf.apply_depositor_metadata('archivist1@example.com')
        gf.read_groups = ['public']
        gf.batch = parent
        gf.save!
      end
    end
    after do
      # GenericFile.find('sufia:5').destroy
    end
    describe "edit" do
      it "should give me a flash error" do
        get :edit, id: generic_file
        expect(response).to fail_redirect_and_flash(main_app.curation_concerns_generic_file_path(generic_file), 'You are not authorized to access this page.')
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
      expect(response).to fail_redirect_and_flash(main_app.new_user_session_path, 'You are not authorized to access this page.')
    end
  end
end
