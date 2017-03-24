require 'spec_helper'

RSpec.describe Hyrax::Admin::WorkflowsController do
  describe "#index" do
    before do
      expect(controller).to receive(:authorize!).with(:read, :admin_dashboard).and_return(true)
    end
    it "is successful" do
      expect(controller).to receive(:add_breadcrumb).with('Home', root_path)
      expect(controller).to receive(:add_breadcrumb).with('Administration', dashboard_path)
      expect(controller).to receive(:add_breadcrumb).with('Tasks', '#')
      expect(controller).to receive(:add_breadcrumb).with('Review Submissions', "/admin/workflows")

      get :index
      expect(response).to be_successful
      expect(assigns[:status_list]).to be_kind_of Hyrax::Workflow::StatusListService
      expect(assigns[:published_list]).to be_kind_of Hyrax::Workflow::StatusListService
    end
  end
end
