require 'spec_helper'

RSpec.describe Sufia::AdminSetsController do
  describe "#index" do
    let(:user) { create(:user) }
    let!(:admin_set) { create(:admin_set, :public) }
    before do
      sign_in user
      create(:collection, :public) # This should not be returned
    end

    it "returns only admin sets" do
      get :index
      expect(response).to be_success
      expect(assigns[:document_list].map(&:id)).to match_array [admin_set.id]
    end
  end
end
