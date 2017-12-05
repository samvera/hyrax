RSpec.describe Hyrax::EmbargoesController do
  let(:user) { create(:user) }
  let(:a_work) { create_for_repository(:work, user: user) }
  let(:not_my_work) { create_for_repository(:work) }

  before { sign_in user }

  describe '#index' do
    context 'when I am NOT a repository manager' do
      it 'redirects' do
        get :index
        expect(response).to redirect_to root_path
      end
    end
    context 'when I am a repository manager' do
      let(:user) { create(:user, groups: ['admin']) }

      it 'shows me the page' do
        get :index
        expect(response).to be_success
      end
    end
  end

  describe '#edit' do
    context 'when I do not have edit permissions for the object' do
      it 'redirects' do
        get :edit, params: { id: not_my_work }
        expect(response.status).to eq 302
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end
    context 'when I have permission to edit the object' do
      it 'shows me the page' do
        get :edit, params: { id: a_work }
        expect(response).to be_success
      end
    end
  end

  describe '#destroy' do
    context 'when I do not have edit permissions for the object' do
      it 'denies access' do
        get :destroy, params: { id: not_my_work }
        expect(response).to fail_redirect_and_flash(root_path, 'You are not authorized to access this page.')
      end
    end

    context 'when I have permission to edit the object' do
      before do
        expect(Hyrax::Actors::EmbargoActor).to receive(:new).with(GenericWork).and_return(actor)
      end

      let(:actor) { double }
      let(:embargo) { instance_double(Hyrax::Embargo, embargo_history: ['it gone']) }

      context 'that has no files' do
        it 'deactivates embargo and redirects' do
          expect(actor).to receive(:destroy).and_return(embargo)
          get :destroy, params: { id: a_work }
          expect(response).to redirect_to edit_embargo_path(a_work)
        end
      end

      context 'that has files' do
        let(:a_work) { create_for_repository(:work_with_one_file, user: user) }

        it 'deactivates embargo and checks to see if we want to copy the visibility to files' do
          expect(actor).to receive(:destroy).and_return(embargo)
          get :destroy, params: { id: a_work }
          expect(response).to redirect_to confirm_permission_path(a_work)
        end
      end
    end
  end

  describe '#update' do
    context 'when I have permission to edit the object' do
      let(:file_set) { create_for_repository(:file_set, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED) }
      let(:embargo) do
        create_for_repository(:embargo,
                              visibility_during_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
                              visibility_after_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
                              embargo_release_date: [release_date])
      end
      let(:a_work) do
        create_for_repository(:work,
                              user: user,
                              member_ids: [file_set.id],
                              visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
                              embargo_id: embargo.id)
      end

      context 'with an expired embargo' do
        let(:release_date) { DateTime.current - 2 }
        let(:reloaded_work) { Hyrax::Queries.find_by(id: a_work.id) }
        let(:reloaded_file_set) { Hyrax::Queries.find_by(id: file_set.id) }

        it 'deactivates embargo, update the visibility and redirect' do
          patch :update, params: { batch_document_ids: [a_work.id], embargoes: { '0' => { copy_visibility: a_work.id } } }
          expect(reloaded_work.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          expect(reloaded_file_set.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          expect(response).to redirect_to embargoes_path
        end
      end
    end
  end
end
