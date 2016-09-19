require 'spec_helper'

describe CurationConcerns::PermissionsController do
  let(:user) { create(:user) }
  let(:work) { create(:work_with_one_file, user: user) }
  before { sign_in user }

  describe '#confirm_access' do
    it 'draws the page' do
      get :confirm_access, params: { id: work }
      expect(response).to be_success
    end
  end

  describe '#copy_access' do
    it 'adds a worker to the queue' do
      expect(VisibilityCopyJob).to receive(:perform_later).with(work)
      expect(InheritPermissionsJob).to receive(:perform_later).with(work)
      post :copy_access, params: { id: work }
      expect(response).to redirect_to main_app.curation_concerns_generic_work_path(work)
      expect(flash[:notice]).to eq 'Updating file access levels. This may take a few minutes. You may want to refresh your browser or return to this record later to see the updated file acess levels.'
    end
  end
end
