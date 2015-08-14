require 'spec_helper'

describe CurationConcerns::PermissionsController do
  let(:user) { FactoryGirl.create(:user) }
  before { sign_in user }

  describe '#confirm' do
    let(:generic_work) { FactoryGirl.create(:generic_work, user: user) }

    it 'draws the page' do
      get :confirm, id: generic_work
      expect(response).to be_success
    end
  end

  describe '#copy' do
    let(:generic_work) { FactoryGirl.create(:generic_work, user: user) }
    let(:worker) { double }

    it 'adds a worker to the queue' do
      expect(VisibilityCopyWorker).to receive(:new).with(generic_work.id).and_return(worker)
      expect(CurationConcerns.queue).to receive(:push).with(worker)
      post :copy, id: generic_work
      expect(response).to redirect_to main_app.curation_concerns_generic_work_path(generic_work)
      expect(flash[:notice]).to eq 'Updating file permissions. This may take a few minutes. You may want to refresh your browser or return to this record later to see the updated file permissions.'
    end
  end
end
