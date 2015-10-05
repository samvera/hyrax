require 'spec_helper'

describe EmbargoesController do
  let(:user) { create(:user) }
  let(:a_work) { create(:generic_work, user: user) }
  let(:not_my_work) { create(:generic_work) }

  before { sign_in user }

  describe '#index' do
    context 'when I am NOT a repository manager' do
      it 'redirects' do
        get :index
        expect(response).to redirect_to root_path
      end
    end
    context 'when I am a repository manager' do
      before { allow_any_instance_of(User).to receive(:groups).and_return(['admin']) }
      it 'shows me the page' do
        get :index
        expect(response).to be_success
      end
    end
  end

  describe '#edit' do
    context 'when I do not have edit permissions for the object' do
      it 'redirects' do
        get :edit, id: not_my_work
        expect(response.status).to eq 302
        expect(flash[:alert]).to eq 'You are not authorized to access this page.'
      end
    end
    context 'when I have permission to edit the object' do
      it 'shows me the page' do
        get :edit, id: a_work
        expect(response).to be_success
      end
    end
  end

  describe '#destroy' do
    context 'when I do not have edit permissions for the object' do
      it 'denies access' do
        get :destroy, id: not_my_work
        expect(response).to fail_redirect_and_flash(root_path, 'You are not authorized to access this page.')
      end
    end

    context 'when I have permission to edit the object' do
      before do
        expect(CurationConcerns::EmbargoActor).to receive(:new).with(a_work).and_return(actor)
      end

      let(:actor) { double }

      context 'that has no files' do
        it 'deactivates embargo and redirects' do
          expect(actor).to receive(:destroy)
          get :destroy, id: a_work
          expect(response).to redirect_to edit_embargo_path(a_work)
        end
      end

      context 'that has files' do
        before do
          a_work.generic_files << create(:generic_file)
          a_work.save!
        end

        it 'deactivates embargo and checks to see if we want to copy the visibility to files' do
          expect(actor).to receive(:destroy)
          get :destroy, id: a_work
          expect(response).to redirect_to confirm_curation_concerns_permission_path(a_work)
        end
      end
    end
  end

  describe '#update' do
    context 'when I have permission to edit the object' do
      let(:a_file) { FactoryGirl.create(:generic_file, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED) }
      let(:release_date) { Date.today + 2 }
      before do
        a_work.generic_files << a_file
        a_work.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        a_work.visibility_during_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        a_work.visibility_after_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        a_work.embargo_release_date = release_date.to_s
        a_work.embargo.save(validate: false)
        a_work.save(validate: false)
      end

      context 'with an expired embargo' do
        let(:release_date) { Date.today - 2 }
        it 'deactivates embargo, update the visibility and redirect' do
          patch :update, batch_document_ids: [a_work.id], embargoes: { '0' => { copy_visibility: a_work.id } }
          expect(a_work.reload.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          expect(a_file.reload.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          expect(response).to redirect_to embargoes_path
        end
      end
    end
  end
end
