require 'spec_helper'

RSpec.describe Hyrax::Admin::AppearancesController do
  describe "#show" do
    before do
      sign_in user
    end
    let(:user) { create(:user) }

    context "when not authorized" do
      it "renders the unauthorized template" do
        get :show
        expect(response).to render_template(:unauthorized)
      end
    end

    context "when authorized" do
      before do
        allow(controller).to receive_messages(current_user: user)
        expect(user).to receive(:groups).and_return(['admin', 'registered'])
      end

      it "is successful" do
        get :show
        expect(assigns[:form]).to be_kind_of Hyrax::Forms::Admin::Appearance
        expect(response).to be_success
      end
    end
  end

  describe "#update" do
    before do
      sign_in user
    end
    let(:user) { create(:user) }
    context "when authorized" do
      before do
        allow(controller).to receive_messages(current_user: user)
        expect(user).to receive(:groups).and_return(['admin', 'registered'])
      end

      it "is successful" do
        patch :update, params: {
          admin_appearance: {
            "header_background_color" => "#00ff00",
            "header_text_color" => "#17557b",
            "primary_button_background_color" => "#00ff00"
          }
        }
        expect(ContentBlock.find_by(name: 'primary_button_background_color').value).to eq '#00ff00'
        expect(response).to be_redirect
      end
    end
  end
end
