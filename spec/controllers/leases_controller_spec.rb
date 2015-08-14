require 'spec_helper'

describe LeasesController do
  let(:user) { FactoryGirl.create(:user) }
  let(:a_work) { FactoryGirl.create(:generic_work, user: user) }
  let(:not_my_work) { FactoryGirl.create(:generic_work) }

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
        expect(ActiveFedora::Base).to receive(:find).with(a_work.id).and_return(a_work)
        a_work.visibility_during_lease = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        a_work.visibility_after_lease = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        a_work.lease_expiration_date = release_date.to_s
        expect(CurationConcerns.queue).to receive(:push).with(an_instance_of(VisibilityCopyWorker))
        get :destroy, id: a_work
      end

      context 'with an active lease' do
        let(:release_date) { Date.today + 2 }
        it 'deactivates the lease without updating visibility and redirect' do
          expect(a_work.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          expect(response).to redirect_to edit_lease_path(a_work)
        end
      end

      context 'with an expired lease' do
        let(:release_date) { Date.today - 2 }

        it 'deactivates the lease, update the visibility and redirect' do
          expect(a_work.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
          expect(response).to redirect_to edit_lease_path(a_work)
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
