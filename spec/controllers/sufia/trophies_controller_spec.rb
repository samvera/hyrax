RSpec.describe Sufia::TrophiesController do
  describe "#toggle_trophy" do
    let(:user) { create(:user) }
    let(:work) { create(:work, user: user) }
    let(:work_id) { work.id }

    context "for a work we have edit access on" do
      before do
        sign_in user
      end
      it "creates a trophy for a work" do
        post :toggle_trophy, id: work_id
        expect(response).to be_success
        json = JSON.parse(response.body)
        expect(json['user_id']).to eq user.id
        expect(json['work_id']).to eq work_id
      end
    end

    context "for a work that we don't have edit access on" do
      it "does not create a trophy" do
        post :toggle_trophy, id: work_id
        expect(response).not_to be_success
      end
    end
  end
end
