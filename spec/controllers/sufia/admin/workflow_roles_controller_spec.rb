require 'spec_helper'

RSpec.describe Sufia::Admin::WorkflowRolesController, :no_clean do
  routes { Sufia::Engine.routes }

  describe "#get" do
    context "when you have permission" do
      before do
        allow(controller).to receive(:authorize!).with(:read, :admin_dashboard).and_return(true)
      end

      it "works" do
        get :index
        expect(response).to be_success
        expect(assigns[:presenter]).to be_kind_of Sufia::Admin::WorkflowRolePresenter
      end
    end

    context "when they don't have permission" do
      it "throws a CanCan error" do
        get :index
        expect(response).to redirect_to main_app.new_user_session_path
      end
    end
  end
end
