require 'spec_helper'

describe CurationConcerns::PermissionsController do
  let(:user) { create(:user) }
  before { sign_in user }

  describe '#confirm' do
    let(:generic_work) { create(:generic_work, user: user) }

    it 'draws the page' do
      get :confirm, id: generic_work
      expect(response).to be_success
    end
  end

  describe '#copy' do
    let(:generic_work) { create(:generic_work, user: user) }

    it 'adds a worker to the queue' do
      expect(VisibilityCopyJob).to receive(:perform_later).with(generic_work)
      post :copy, id: generic_work
      expect(response).to redirect_to main_app.curation_concerns_generic_work_path(generic_work)
      expect(flash[:notice]).to eq 'Updating file permissions. This may take a few minutes. You may want to refresh your browser or return to this record later to see the updated file permissions.'
    end
  end
end
