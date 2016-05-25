describe Admin::StatsController, type: :controller do
  let(:user1) { create(:user) }

  before do
    allow(user1).to receive(:groups).and_return(['admin'])
  end

  describe "#index" do
    before do
      sign_in user1
    end

    it 'allows an authorized user to view the page' do
      expect(Sufia::AdminStatsPresenter).to receive(:new).with({}, 5).and_call_original
      get :index
      expect(response).to be_success
      expect(assigns[:presenter]).to be_kind_of Sufia::AdminStatsPresenter
    end
  end
end
