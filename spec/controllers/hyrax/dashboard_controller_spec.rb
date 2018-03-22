RSpec.describe Hyrax::DashboardController, type: :controller do
  context "with an unauthenticated user" do
    it "redirects to sign-in page" do
      get :show
      expect(response).to be_redirect
      expect(flash[:alert]).to eq("You need to sign in or sign up before continuing.")
    end
  end

  context "with an authenticated user" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "renders the dashboard with the user's info" do
      get :show
      expect(response).to be_successful
      expect(assigns(:presenter)).to be_instance_of Hyrax::Dashboard::UserPresenter
      expect(response).to render_template('show_user')
    end
  end

  context 'with an admin user' do
    let(:service_collections) { instance_double(Hyrax::CollectionsCountService, search_results_with_work_count: results_collections) }
    let(:service_works) { instance_double(Hyrax::WorksCountService, search_results_with_work_count: results_works) }
    let(:results_collections) { instance_double(Array) }
    let(:results_works) { instance_double(Array) }
    let(:repo_growth) { Hyrax::Admin::RepositoryGrowthPresenter.new(90) }
    let(:repo_objects) { Hyrax::Admin::RepositoryObjectPresenter.new('visible') }
    let(:user) { create(:admin) }
    let(:access) { :edit }
    let(:read_admin_dashboard) { true }

    before do
      sign_in user
      allow(Hyrax::CollectionsCountService).to receive(:new).and_return(service_collections)
      allow(Hyrax::WorksCountService).to receive(:new).and_return(service_works)
      allow(Hyrax::Admin::RepositoryGrowthPresenter).to receive(:new).and_return(repo_growth)
      allow(Hyrax::Admin::RepositoryObjectPresenter).to receive(:new).and_return(repo_objects)
    end

    it "is successful" do
      get :show
      expect(response).to be_success
      expect(assigns[:collection_rows]).to eq results_collections
      expect(response).to render_template('show_admin')
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

    it "renders works" do
      get :update_works_list
      expect(response).to be_success
      expect(assigns[:work_rows]).to eq results_works
    end
  end
end
