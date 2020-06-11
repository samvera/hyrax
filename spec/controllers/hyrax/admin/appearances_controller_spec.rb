# frozen_string_literal: true
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
        expect(controller).to receive(:add_breadcrumb).with('Home', root_path)
        expect(controller).to receive(:add_breadcrumb).with('Dashboard', dashboard_path)
        expect(controller).to receive(:add_breadcrumb).with('Configuration', '#')
        expect(controller).to receive(:add_breadcrumb).with('Appearance', "/admin/appearance")
        get :show
        expect(assigns[:form]).to be_kind_of Hyrax::Forms::Admin::Appearance
        expect(response).to be_successful
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

      let(:form) { instance_double(Hyrax::Forms::Admin::Appearance, update!: true) }
      let(:attributes) do
        {
          "header_background_color" => "#00ff00",
          "link_color" => "#e02020",
          "footer_link_color" => "#e02020",
          "header_text_color" => "#17557b",
          "primary_button_background_color" => "#00ff00"
        }
      end

      it "is successful" do
        expect(Hyrax::Forms::Admin::Appearance).to receive(:new)
          .with(ActionController::Parameters.new(attributes).permit!)
          .and_return(form)

        patch :update, params: { admin_appearance: attributes }
        expect(response).to be_redirect
      end
    end
  end
end
