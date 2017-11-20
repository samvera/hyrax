RSpec.describe Hyrax::FeaturedWorkListsController, type: :controller do
  describe "#create" do
    before do
      expect(controller).to receive(:authorize!).with(:update, FeaturedWork)
    end

    let(:feature1) { create(:featured_work) }
    let(:feature2) { create(:featured_work) }

    it "is successful" do
      post :create, params: {
        format: :json,
        featured_work_list: {
          featured_works_attributes: [{ id: feature1.id, order: "2" }, { id: feature2.id, order: "1" }]
        }
      }
      expect(feature1.reload.order).to eq 2
    end
  end
end
