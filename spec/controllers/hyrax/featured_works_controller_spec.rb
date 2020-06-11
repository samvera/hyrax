# frozen_string_literal: true
RSpec.describe Hyrax::FeaturedWorksController, type: :controller do
  describe "#create" do
    before do
      sign_in create(:user)
      expect(controller).to receive(:authorize!).with(:create, FeaturedWork).and_return(true)
    end

    context "when there are no featured works" do
      it "creates one" do
        expect do
          post :create, params: { id: '1234abcd', format: :json }
        end.to change { FeaturedWork.count }.by(1)
        expect(response).to be_successful
      end
    end

    context "when there are 5 featured works" do
      before do
        5.times do |n|
          FeaturedWork.create(work_id: n.to_s)
        end
      end
      it "does not create another" do
        expect do
          post :create, params: { id: '1234abcd', format: :json }
        end.not_to change { FeaturedWork.count }
        expect(response.status).to eq 422
      end
    end
  end

  describe "#destroy" do
    before do
      sign_in create(:user)
      expect(controller).to receive(:authorize!).with(:destroy, FeaturedWork).and_return(true)
    end

    context "when the work exists" do
      before { create(:featured_work, work_id: '1234abcd') }

      it "removes it" do
        expect do
          delete :destroy, params: { id: '1234abcd', format: :json }
        end.to change { FeaturedWork.count }.by(-1)
        expect(response.status).to eq 204
      end
    end

    context "when it was already removed" do
      it "doesn't raise an error" do
        delete :destroy, params: { id: '1234abcd', format: :json }
        expect(response.status).to eq 204
      end
    end
  end
end
