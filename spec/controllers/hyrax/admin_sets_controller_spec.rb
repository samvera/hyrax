require 'spec_helper'

RSpec.describe Hyrax::AdminSetsController do
  describe "#index" do
    let!(:admin_set) { create(:admin_set, :public) }
    before do
      create(:collection, :public) # This should not be returned
    end

    it "returns only admin sets" do
      get :index
      expect(response).to be_success
      expect(assigns[:document_list].map(&:id)).to match_array [admin_set.id]
    end
  end

  describe "#show" do
    let(:admin_set) { create(:admin_set, :public) }
    let!(:work) { create(:work, :public, admin_set: admin_set) }

    it "returns a presenter and members" do
      get :show, params: { id: admin_set }
      expect(response).to be_success
      expect(assigns[:presenter].id).to eq admin_set.id
      expect(assigns[:member_docs].map(&:id)).to eq [work.id]
    end
  end
end
