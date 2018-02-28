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
    let(:service) { instance_double(Hyrax::AdminSetService, search_results_with_work_count: results) }
    let(:results) { instance_double(Array) }
    let(:user) { create(:admin) }
    let(:access) { :edit }
    let(:read_admin_dashboard) { true }

    before do
      sign_in user
      allow(Hyrax::AdminSetService).to receive(:new).and_return(service)
    end

    it "is successful" do
      get :show
      expect(response).to be_success
      expect(assigns[:admin_set_rows]).to eq results
      expect(response).to render_template('show_admin')
    end

    context 'with updated table' do
      let(:response) do
        allow(DashboardController).to receive(:get_data).and_return(response)
      end

      def response
        {
            'rows' => '<tr><td>dd</td></tr>'
        }.to_json
      end

      it "returns json" do
        get :update_collections
        parsed_response = JSON.parse(response)
        puts parsed_response['rows']
        expect(parsed_response['rows']).to eq('<tr><td>dd</td></tr>')
      end
    end
  end
end
