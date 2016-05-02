require 'spec_helper'

describe CurationConcerns::FileSetsController do
  let(:user) { create(:user) }
  let(:file) { fixture_file_upload('files/image.png', 'image/png') }
  let(:parent) { create(:generic_work, edit_users: [user.user_key], visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC) }

  context 'when signed in' do
    before { sign_in user }

    describe '#create' do
      before do
        FileSet.destroy_all
      end

      context 'on the happy path' do
        let(:date_today) { DateTime.now }

        before do
          allow(DateTime).to receive(:now).and_return(date_today)
        end

        it 'calls the actor to create metadata and content' do
          expect(controller.send(:actor)).to receive(:create_metadata).with(parent, files: [file], title: ['test title'], visibility: 'restricted')
          expect(controller.send(:actor)).to receive(:create_content).with(file).and_return(true)
          xhr :post, :create, parent_id: parent,
                              file_set: { files: [file],
                                          title: ['test title'],
                                          visibility: 'restricted' }
          expect(response).to be_success
          expect(flash[:error]).to be_nil
        end
      end

      context "on something that isn't a file" do
        # Note: This is a duplicate of coverage in file_sets_controller_json_spec.rb
        it 'renders error' do
          xhr :post, :create, parent_id: parent, file_set: { files: ['hello'] },
                              permission: { group: { 'public' => 'read' } }, terms_of_service: '1'
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
          allow(ClamAV.instance).to receive(:scanfile).and_return('EL CRAPO VIRUS')
          of = subject.build_original_file
          of.content = File.open(file_path)
        end
        it 'populates the errors hash during validation' do
          expect(subject).to_not be_valid
          expect(subject.errors.messages[:base].first).to match(/A virus was found in .*: EL CRAPO VIRUS/)
        end
      end

      context 'when solr is down' do
        before do
          allow(controller.send(:actor)).to receive(:create_metadata)
          allow(controller.send(:actor)).to receive(:create_content).with(file).and_raise(RSolr::Error::Http.new({}, {}))
        end

        it 'errors out of create after on continuous rsolr error' do
          xhr :post, :create, parent_id: parent, file_set: { files: [file] },
                              permission: { group: { 'public' => 'read' } }, terms_of_service: '1'
          expect(response.body).to include('Error occurred while creating a FileSet.')
        end
      end

      context 'when the file is not created' do
        before do
          allow(controller.send(:actor)).to receive(:create_metadata)
          allow(controller.send(:actor)).to receive(:create_content).with(file).and_return(false)
        end

        it 'errors out of create after on continuous rsolr error' do
          xhr :post, :create, parent_id: parent, file_set: { files: [file] },
                              permission: { group: { 'public' => 'read' } }, terms_of_service: '1'
          expect(response.body).to include('Error creating file image.png')
        end
      end
    end

    describe 'destroy' do
      let(:file_set) do
        file_set = FileSet.create! do |gf|
          gf.apply_depositor_metadata(user)
        end
        parent.ordered_members << file_set
        parent.save
        file_set
      end

      it 'deletes the file' do
        expect(FileSet.find(file_set.id)).to be_kind_of FileSet
        delete :destroy, id: file_set
        expect { FileSet.find(file_set.id) }.to raise_error Ldp::Gone
        expect(response).to redirect_to main_app.curation_concerns_generic_work_path(parent)
      end
    end

    describe 'update' do
      let!(:file_set) do
        file_set = FileSet.create do |gf|
          gf.apply_depositor_metadata(user)
          gf.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        end
        parent.ordered_members << file_set
        parent.save
        file_set
      end

      after do
        file_set.destroy
      end

      context 'updating metadata' do
        it 'is successful and update attributes' do
          post :update, id: file_set, file_set:
            { title: ['new_title'], tag: [''], permissions_attributes: [{ type: 'person', name: 'archivist1', access: 'edit' }] }
          expect(response).to redirect_to main_app.curation_concerns_file_set_path(file_set)
          expect(assigns[:file_set].title).to eq(['new_title'])
        end

        it 'goes back to edit on an error' do
          allow_any_instance_of(FileSet).to receive(:valid?).and_return(false)
          post :update, id: file_set, file_set:
            { title: ['new_title'], tag: [''], permissions_attributes: [{ type: 'person', name: 'archivist1', access: 'edit' }] }
          expect(response.status).to eq 422
          expect(response).to render_template('edit')
          expect(assigns[:groups]).to be_kind_of Array
          expect(assigns[:file_set]).to eq file_set
          expect(flash[:error]).to eq "There was a problem processing your request."
        end

        context 'updating visibility' do
          it 'applies public' do
            new_visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
            post :update, id: file_set, file_set: { visibility: new_visibility, embargo_release_date: '' }
            expect(file_set.reload.visibility).to eq new_visibility
          end

          it 'applies embargo' do
            post :update, id: file_set, file_set: {
              visibility: 'embargo',
              visibility_during_embargo: 'restricted',
              embargo_release_date: '2099-09-05',
              visibility_after_embargo: 'open',
              visibility_during_lease: 'open',
              lease_expiration_date: '2099-09-05',
              visibility_after_lease: 'restricted'
            }
            file_set.reload
            expect(file_set).to be_under_embargo
            expect(file_set).to_not be_active_lease
          end
        end
      end

      context 'updating file content' do
        it 'is successful' do
          expect(IngestFileJob).to receive(:perform_later)
          expect(CharacterizeJob).to receive(:perform_later).with(file_set, kind_of(String))
          post :update, id: file_set, file_set: { files: [file] }
          expect(response).to redirect_to main_app.curation_concerns_file_set_path(file_set)
        end
      end

      context 'restoring an old version' do
        before do
          # don't run characterization jobs
          allow(CharacterizeJob).to receive(:perform_later)
          # Create version 1
          Hydra::Works::AddFileToFileSet.call(file_set, File.open(fixture_file_path('small_file.txt')), :original_file)
          # Create version 2
          Hydra::Works::AddFileToFileSet.call(file_set, File.open(fixture_file_path('curation_concerns_generic_stub.txt')), :original_file)
        end

        # TODO: This test should move into the FileSetActor spec and just ensure the actor is called.
        it 'is successful' do
          expect(file_set.latest_content_version.label).to eq('version2')
          expect(file_set.original_file.content).to eq("This is a test fixture for curation_concerns: <%= @id %>.\n")
          post :update, id: file_set, revision: 'version1'
          expect(response).to redirect_to main_app.curation_concerns_file_set_path(file_set)
          reloaded = file_set.reload.original_file
          expect(reloaded.versions.last.label).to eq 'version3'
          expect(reloaded.content).to eq "small\n"
          expect(reloaded.mime_type).to eq 'text/plain'
        end
      end
    end
  end

  context 'someone elses (public) files' do
    let(:creator) { create(:user, email: 'archivist1@example.com') }
    let(:public_file_set) { create(:file_set, user: creator, read_groups: ['public']) }
    before { sign_in user }

    describe '#edit' do
      it 'gives me the unauthorized page' do
        get :edit, id: public_file_set
        expect(response.code).to eq '401'
        expect(response).to render_template(:unauthorized)
      end
    end

    describe '#show' do
      it 'allows access to the file' do
        get :show, id: public_file_set
        expect(response).to be_success
      end
    end
  end

  context 'when not signed in' do
    let(:private_file_set) { create(:file_set) }
    let(:public_file_set) { create(:file_set, read_groups: ['public']) }

    describe '#edit' do
      it 'requires login' do
        get :edit, id: public_file_set
        expect(response).to fail_redirect_and_flash(main_app.new_user_session_path, 'You are not authorized to access this page.')
      end
    end

    describe '#show' do
      it 'denies access to private files' do
        get :show, id: private_file_set
        expect(response).to fail_redirect_and_flash(main_app.new_user_session_path, 'You are not authorized to access this page.')
      end

      it 'allows access to public files' do
        expect(controller).to receive(:additional_response_formats).with(ActionController::MimeResponds::Collector)
        get :show, id: public_file_set
        expect(response).to be_success
      end
    end

    describe '#new' do
      it 'does not let the user submit' do
        get :new, parent_id: parent
        expect(response).to fail_redirect_and_flash(main_app.new_user_session_path, 'You are not authorized to access this page.')
      end
    end
  end

  context 'finds parents' do
    let(:file_set) do
      file_set = FileSet.create! do |gf|
        gf.apply_depositor_metadata(user)
      end
      parent.ordered_members << file_set
      parent.save
      file_set
    end

    before do
      allow_any_instance_of(described_class).to receive(:curation_concern).and_return(file_set)
    end

    it 'finds a parent' do
      expect(controller.parent).to eq(parent)
    end

    it 'finds a parent id' do
      expect(controller.parent_id).to eq(parent.id)
    end
  end
end
