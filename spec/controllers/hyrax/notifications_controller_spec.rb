# frozen_string_literal: true
RSpec.describe Hyrax::NotificationsController, type: :controller do
  let(:mock_box) { {} }

  before do
    allow(controller).to receive(:authenticate_user!).and_return(true)
    allow(UserMailbox).to receive(:new).and_return(mock_box)
  end

  describe "#index" do
    it "shows message" do
      expect(mock_box).to receive(:inbox).and_return(["test"])
      expect(StreamNotificationsJob).to receive(:perform_later).once
      get :index
      expect(response).to be_successful
      expect(assigns[:messages]).to eq(["test"])
    end
  end

  describe "#delete_all" do
    it "deletes all messages" do
      expect(mock_box).to receive(:delete_all)
      get :delete_all
    end
  end

  describe "#delete" do
    it "deletes message" do
      expect(mock_box).to receive(:destroy).with("4")
      delete :destroy, params: { id: "4" }
      expect(response).to redirect_to(routes.url_helpers.notifications_path(locale: 'en'))
    end
  end
end
