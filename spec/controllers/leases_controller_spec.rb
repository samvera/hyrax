require 'spec_helper'

describe LeasesController do
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
      let(:actor) { double('lease actor') }
      before do
        allow(CurationConcerns::LeaseActor).to receive(:new).with(a_work).and_return(actor)
      end

      context 'that has no files' do
        it 'deactivates the lease and redirects' do
          expect(actor).to receive(:destroy)
          get :destroy, id: a_work
          expect(response).to redirect_to edit_lease_path(a_work)
        end
      end

      context 'with files' do
        before do
          a_work.generic_files << create(:generic_file)
          a_work.save!
        end

        it 'deactivates the lease and redirects' do
          expect(actor).to receive(:destroy)
          get :destroy, id: a_work
          expect(response).to redirect_to confirm_curation_concerns_permission_path(a_work)
        end
      end
    end
  end

  describe '#update' do
    context 'when I have permission to edit the object' do
      before do
        expect(ActiveFedora::Base).to receive(:find).with(a_work.id).and_return(a_work)
      end
      it 'deactivates lease and redirect' do
        expect(a_work).to receive(:deactivate_lease!)
        expect(a_work).to receive(:save)
        patch :update, batch_document_ids: [a_work.id]
        expect(response).to redirect_to leases_path
      end
    end
  end
end
