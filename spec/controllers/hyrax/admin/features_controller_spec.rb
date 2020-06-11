# frozen_string_literal: true
RSpec.describe Hyrax::Admin::FeaturesController do
  describe "#index" do
    before do
      sign_in user
    end
    let(:user) { create(:user) }

    context "when not authorized" do
      it "redirects away" do
        get :index
        expect(response).to redirect_to root_path
      end
    end

    context "when authorized" do
      before do
        allow(controller).to receive_messages(current_user: user)
        expect(user).to receive(:groups).and_return(['admin', 'registered'])
      end

      it "is successful" do
        expect(controller).to receive(:add_breadcrumb).with('Home', root_path)
        expect(controller).to receive(:add_breadcrumb).with('Dashboard', dashboard_path)
        expect(controller).to receive(:add_breadcrumb).with('Configuration', '#')
        expect(controller).to receive(:add_breadcrumb).with('Features', admin_features_path)
        get :index
        expect(response).to be_successful
      end
    end
  end
end
