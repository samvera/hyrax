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
      expect(assigns[:status_list]).to be_kind_of Hyrax::Workflow::StatusListService
      expect(assigns[:published_list]).to be_kind_of Hyrax::Workflow::StatusListService
    end
  end
end
