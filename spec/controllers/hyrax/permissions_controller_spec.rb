require 'spec_helper'

describe Hyrax::PermissionsController do
  let(:user) { create(:user) }
  before do
    sign_in user
    allow(ActiveFedora::Base).to receive(:find).with(work.id).and_return(work)
  end

  describe '#confirm' do
    let(:work) { build(:generic_work, user: user, id: 'abc') }

    it 'draws the page' do
      get :confirm, params: { id: work }
      expect(response).to be_success
    end
  end

  describe '#copy' do
    let(:work) { create(:generic_work, user: user) }

    it 'adds a worker to the queue' do
      expect(VisibilityCopyJob).to receive(:perform_later).with(work)
      post :copy, params: { id: work }
      expect(response).to redirect_to main_app.hyrax_generic_work_path(work, locale: 'en')
      expect(flash[:notice]).to eq 'Updating file permissions. This may take a few minutes. You may want to refresh your browser or return to this record later to see the updated file permissions.'
    end
  end

  describe '#confirm_access' do
    let(:work) { create(:work_with_one_file, user: user) }

    it 'draws the page' do
      get :confirm_access, params: { id: work }
      expect(response).to be_success
    end
  end

  describe '#copy_access' do
    let(:work) { create(:work_with_one_file, user: user) }

    it 'adds a worker to the queue' do
      expect(VisibilityCopyJob).to receive(:perform_later).with(work)
      expect(InheritPermissionsJob).to receive(:perform_later).with(work)
      post :copy_access, params: { id: work }
      expect(response).to redirect_to main_app.hyrax_generic_work_path(work, locale: 'en')
      expect(flash[:notice]).to eq 'Updating file access levels. This may take a few minutes. ' \
                                   'You may want to refresh your browser or return to this record ' \
                                   'later to see the updated file access levels.'
    end
  end
end
