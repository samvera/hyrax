require 'spec_helper'

RSpec.describe CurationConcerns::AdminController do
  routes { CurationConcerns::Engine.routes }
  describe "GET /admin" do
    context "when you have permission" do
      let(:user) { FactoryGirl.create(:admin) }
      before do
        allow(controller).to receive(:authorize!).with(:read, :admin_dashboard).and_return(true)
      end
      it "works" do
        get :index
        expect(response).to be_success
      end
    end
    context "when they don't have permission" do
      it "throws a CanCan error" do
        get :index
        expect(response).to redirect_to new_user_session_path
      end
    end
  end

  describe "GET missing_thing" do
    before do
      # Add necessary route.
      # TODO: Consider a different pattern for this.
      CurationConcerns::Engine.routes.draw do
        get '/admin/missing_thing' => 'admin#missing_thing'
      end

      allow(controller).to receive(:authorize!).with(:read, :admin_dashboard).and_return(true)
    end
    after do
      Rails.application.reload_routes!
    end
    context "when it exists in the configuration" do
      before do
        config = CurationConcerns.config.dashboard_configuration
        config[:actions] = config[:actions].merge(missing_thing: {})
        described_class.configuration = config
      end
      it "renders index" do
        get :missing_thing

        expect(response).to render_template "index"
      end
    end
  end
end
