describe Hyrax::Admin::StatsController, type: :controller do
  let(:user) { create(:user) }

  context "a non admin" do
    describe "#show" do
      it 'is unauthorized' do
        get :show
        expect(response).to be_redirect
      end
    end
  end

  context "as an admin" do
    before do
      allow(controller).to receive(:authorize!).and_return(true)
    end

    describe "#show" do
      let(:expected_params) do
        ActionController::Parameters.new
      end

      it 'allows an authorized user to view the page' do
        expect(Hyrax::AdminStatsPresenter).to receive(:new).with(expected_params, 5).and_call_original
        get :show
        expect(response).to be_success
        expect(assigns[:presenter]).to be_kind_of Hyrax::AdminStatsPresenter
      end
    end
  end
end
