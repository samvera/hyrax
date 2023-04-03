# frozen_string_literal: true
RSpec.describe Hyrax::Admin::WorkflowsController do
  describe "#index" do
    let(:user) { FactoryBot.create(:admin) }

    before { sign_in user }

    it "is successful" do
      expect(controller).to receive(:add_breadcrumb).with('Home', root_path)
      expect(controller).to receive(:add_breadcrumb).with('Dashboard', dashboard_path)
      expect(controller).to receive(:add_breadcrumb).with('Tasks', '#')
      expect(controller).to receive(:add_breadcrumb).with('Review Submissions', "/admin/workflows")

      get :index
      expect(response).to be_successful
      expect(assigns[:response].docs).to respond_to(:each)
      expect(assigns[:response].total_pages).to eq 0
      expect(assigns[:response].limit_value).to eq 0
      expect(assigns[:response].current_page).to eq 1
      expect(assigns[:response].per_page).to eq 10
      expect(assigns[:response].viewing_under_review?).to be_truthy
    end

    it "is successful with parameters provided" do
      expect(controller).to receive(:add_breadcrumb).with('Home', root_path)
      expect(controller).to receive(:add_breadcrumb).with('Dashboard', dashboard_path)
      expect(controller).to receive(:add_breadcrumb).with('Tasks', '#')
      expect(controller).to receive(:add_breadcrumb).with('Review Submissions', "/admin/workflows")

      get :index, params: { state: 'published', per_page: '50', page: 2 }
      expect(response).to be_successful
      expect(assigns[:response].docs).to respond_to(:each)
      expect(assigns[:response].total_pages).to eq 0
      expect(assigns[:response].limit_value).to eq 0
      expect(assigns[:response].current_page).to eq 2
      expect(assigns[:response].per_page).to eq 50
      expect(assigns[:response].viewing_under_review?).to be_falsey
    end
  end
end
