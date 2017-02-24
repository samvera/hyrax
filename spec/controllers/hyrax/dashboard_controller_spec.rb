describe Hyrax::DashboardController, type: :controller do
  context "with an unauthenticated user" do
    it "redirects to sign-in page" do
      get :show
      expect(response).to be_redirect
      expect(flash[:alert]).to eq("You need to sign in or sign up before continuing.")
    end
  end

  context "with an authenticated user" do
    let(:user) { create(:user_with_mail) }

    before do
      sign_in user
    end

    it "renders the dashboard with the user's info" do
      get :show
      expect(response).to be_successful
      expect(assigns(:activity)).to be_empty
      expect(assigns(:notifications)).to be_truthy
      expect(response).to render_template('show_user')
    end

    context 'with transfers' do
      let(:another_user) { create(:user) }
      context 'when incoming' do
        let!(:incoming_work) do
          GenericWork.new(title: ['incoming']) do |w|
            w.apply_depositor_metadata(another_user.user_key)
            w.save!
            w.request_transfer_to(user)
          end
        end

        it 'assigns an instance variable' do
          get :show
          expect(response).to be_success
          expect(assigns[:incoming].first).to be_kind_of ProxyDepositRequest
          expect(assigns[:incoming].first.work_id).to eq(incoming_work.id)
        end
      end

      context 'when outgoing' do
        let!(:outgoing_work) do
          GenericWork.new(title: ['outgoing']) do |w|
            w.apply_depositor_metadata(user.user_key)
            w.save!
            w.request_transfer_to(another_user)
          end
        end

        it 'assigns an instance variable' do
          get :show
          expect(response).to be_success
          expect(assigns[:outgoing].first).to be_kind_of ProxyDepositRequest
          expect(assigns[:outgoing].first.work_id).to eq(outgoing_work.id)
        end
      end
    end

    context "with activities" do
      let(:activity) { double }

      before do
        allow(activity).to receive(:map).and_return(activity)
        allow_any_instance_of(User).to receive(:all_user_activity).and_return(activity)
      end

      it "gathers the user's recent activity within the default amount of time" do
        get :show
        expect(assigns(:activity)).to eq activity
      end
    end
  end

  context 'with an admin user' do
    let(:service) { instance_double(Hyrax::AdminSetService, search_results_with_work_count: results) }
    let(:results) { instance_double(Array) }
    let(:user) { create(:admin) }

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
  end
end
