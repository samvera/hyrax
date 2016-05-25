describe FeaturedWorksController, type: :controller do
  describe "#create" do
    before do
      sign_in FactoryGirl.create(:user)
      expect(controller).to receive(:authorize!).with(:create, FeaturedWork).and_return(true)
    end

    context "when there are no featured works" do
      it "creates one" do
        expect {
          post :create, id: '1234abcd', format: :json
        }.to change { FeaturedWork.count }.by(1)
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
        expect {
          post :create, id: '1234abcd', format: :json
        }.to_not change { FeaturedWork.count }
        expect(response.status).to eq 422
      end
    end
  end

  describe "#destroy" do
    let!(:featured_work) { FactoryGirl.create(:featured_work, work_id: '1234abcd') }

    before do
      sign_in FactoryGirl.create(:user)
      expect(controller).to receive(:authorize!).with(:destroy, FeaturedWork).and_return(true)
    end

    it "removes it" do
      expect {
        delete :destroy, id: '1234abcd', format: :json
      }.to change { FeaturedWork.count }.by(-1)
      expect(response.status).to eq 204
    end
  end
end
