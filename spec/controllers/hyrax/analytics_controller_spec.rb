RSpec.describe Hyrax::AnalyticsController, type: :controller do
  context 'with an admin user' do
    let(:results_works) { instance_double(Array) }
    let(:repo_growth) { Hyrax::Admin::RepositoryGrowthPresenter.new(90) }
    let(:repo_objects) { Hyrax::Admin::RepositoryObjectPresenter.new('visible') }
    let(:service_works) { instance_double(Hyrax::WorksCountService, search_results_with_work_count: results_works) }
    let(:user) { create(:admin) }
    let(:access) { :edit }
    let(:read_admin_dashboard) { true }
    let(:results_works) { instance_double(Array) }
    let(:pinned_collections) { { collection: 123, user_id: 1, pinned: 1 } }
    let(:pin) { true }
    let(:repo_growth) { Hyrax::Admin::RepositoryGrowthPresenter.new(90) }
    let(:repo_objects) { Hyrax::Admin::RepositoryObjectPresenter.new('visible') }
    let(:pinned_objects) { Hyrax::Admin::PinCollectionPresenter.new(user_id: 1, collection: 123, pinned: 1) }
    let(:service_works) { instance_double(Hyrax::WorksCountService, search_results_with_work_count: results_works) }

    before do
      sign_in user
      allow(Hyrax::Admin::RepositoryGrowthPresenter).to receive(:new).and_return(repo_growth)
      allow(Hyrax::Admin::RepositoryObjectPresenter).to receive(:new).and_return(repo_objects)
      allow(Hyrax::Admin::PinCollectionPresenter).to receive(:new).and_return(pinned_objects)
      allow(Hyrax::WorksCountService).to receive(:new).and_return(service_works)
    end

    it 'sends repository_growth counts' do
      get :repository_growth
      expect(response).to be_success
      expect(assigns[:repo_growth]).to eq repo_growth
    end

    it 'sends repository object counts' do
      get :repository_object_counts
      expect(response).to be_success
      expect(assigns[:repo_objects]).to eq repo_objects
    end

    it 'renders works' do
      get :update_works_list
      expect(response).to be_success
      expect(assigns[:work_rows]).to eq results_works
    end

    it 'pins collection' do
      post :pin_collection
      expect(response).to be_success
      expect(assigns[:pinned].pin_collection).to eq pinned_objects.pin_collection
    end

    it 'returns a users pinned collections' do
      get :all_pinned_collections
      expect(response).to be_success
      expect(assigns[:all].all_pinned_collections).to eq pinned_objects.all_pinned_collections
    end
  end

  context 'with a non-admin user' do
    let(:user) { create(:user) }
    let(:read_admin_dashboard) { false }

    it 'does not pin collections' do
      post :pin_collection
      expect(response).not_to be_success
    end

    it 'does not return a users pinned collections' do
      get :all_pinned_collections
      expect(response).not_to be_success
    end
  end
end
