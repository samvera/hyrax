# frozen_string_literal: true
RSpec.describe Hyrax::OperationsController do
  routes { Hyrax::Engine.routes }
  let(:parent) { create(:operation, :pending, user: user) }
  let!(:child1) { create(:operation, :failing, parent: parent, user: user) }
  let!(:child2) { create(:operation, :pending, parent: parent, user: user) }
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "#index" do
    it "is successful" do
      get :index, params: { user_id: user }
      expect(response).to be_successful
      expect(assigns[:operations]).to eq [parent]
    end
  end

  describe "#show" do
    it "is successful" do
      get :show, params: { user_id: user, id: parent }
      expect(response).to be_successful
      expect(assigns[:operation]).to eq parent
    end
  end
end
