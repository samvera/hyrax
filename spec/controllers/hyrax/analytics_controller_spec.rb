RSpec.describe Hyrax::AnalyticsController, type: :controller do
  context 'with an admin user' do
    let(:repo_growth) { Hyrax::Admin::RepositoryGrowthPresenter.new(90) }
    let(:repo_objects) { Hyrax::Admin::RepositoryObjectPresenter.new('visible') }
    let(:user) { create(:admin) }
    let(:access) { :edit }
    let(:read_admin_dashboard) { true }

    before do
      sign_in user
      allow(Hyrax::Admin::RepositoryGrowthPresenter).to receive(:new).and_return(repo_growth)
      allow(Hyrax::Admin::RepositoryObjectPresenter).to receive(:new).and_return(repo_objects)
    end

    it "sends repository_growth counts" do
      get :repository_growth
      expect(response).to be_success
      expect(assigns[:repo_growth]).to eq repo_growth
    end

    it "sends repository object counts" do
      get :repository_object_counts
      expect(response).to be_success
      expect(assigns[:repo_objects]).to eq repo_objects
    end
  end
end
