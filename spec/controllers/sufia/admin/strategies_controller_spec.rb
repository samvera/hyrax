require 'spec_helper'

RSpec.describe Sufia::Admin::StrategiesController do
  describe "#update" do
    before do
      sign_in user
    end
    let(:user) { create(:user) }

    context "when not authorized" do
      it "redirects away" do
        patch :update, params: { feature_id: '123', id: 'database' }
        expect(response).to redirect_to root_path
      end
    end

    context "when authorized" do
      before do
        allow(controller).to receive_messages(current_user: user)
        expect(user).to receive(:groups).and_return(['admin', 'registered'])
      end

      it "is successful" do
        patch :update, params: { feature_id: '123', id: 'database' }
        expect(response).to redirect_to Sufia::Engine.routes.url_helpers.admin_features_path
      end
    end
  end
end
