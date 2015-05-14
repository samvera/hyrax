require 'spec_helper'

describe CurationConcern::PermissionsController do
  let(:user) { FactoryGirl.create(:user) }
  before { sign_in user }
  render_views

  describe "#confirm" do
    let(:generic_work) { FactoryGirl.create(:generic_work, user: user) }
    it "should draw the page" do
      get :confirm, id: generic_work
      expect(response).to be_success
    end
  end

  describe "#copy_visibility" do
    let(:generic_work) { FactoryGirl.create(:generic_work, user: user) }
    it "should add a worker to the queue" do
      worker = double
      CopyPermissionsJob.should_receive(:new).with(generic_work.id).and_return(worker)
      Sufia.queue.should_receive(:push).with(worker)
      post :copy, id: generic_work
      expect(response).to redirect_to Sufia::Engine.routes.url_helpers.generic_work_path(generic_work)
      expect(flash[:notice]).to eq 'Updating file permissions. This may take a few minutes. You may want to refresh your browser or return to this record later to see the updated file permissions.'
    end
  end

end
