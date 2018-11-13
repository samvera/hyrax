RSpec.describe Hyrax::DepositorsController do
  let(:user) { create(:user) }
  let(:grantee) { create(:user) }

  let(:grant_proxy_params) do
    {
      user_id: user.user_key,
      grantee_id: grantee.user_key,
      format: 'json'
    }
  end

  let(:revoke_proxy_params) do
    {
      user_id: user.user_key,
      id: grantee.user_key,
      format: 'json'
    }
  end

  context "as a logged in user" do
    before do
      sign_in user
    end

    describe "#create" do
      context 'when the grantee has not yet been designated as a depositor' do
        let(:request_to_grant_proxy) { post :create, params: grant_proxy_params }

        it 'is successful' do
          expect { request_to_grant_proxy }.to change { ProxyDepositRights.count }.by(1)
          expect(response).to be_success
        end

        it 'sends a message to the grantor' do
          expect { request_to_grant_proxy }.to change { user.mailbox.inbox.count }.by(1)
          expect(user.mailbox.inbox.last.last_message.subject).to eq 'Proxy Depositor Added'
          expect(user.mailbox.inbox.last.last_message.body).to eq 'You have assigned ' + grantee.user_key + ' as a proxy depositor'
        end

        it 'sends a message to the grantee' do
          expect { request_to_grant_proxy }.to change { grantee.mailbox.inbox.count }.by(1)
          expect(grantee.mailbox.inbox.last.last_message.subject).to eq 'Proxy Depositor Added'
          expect(grantee.mailbox.inbox.last.last_message.body).to eq user.user_key + ' has assigned you as a proxy depositor'
        end
      end

      context 'when the grantee is already an allowed depositor' do
        # For this test we just set the grantor to be eq to grantee.
        let(:redundant_request_to_grant_proxy) do
          post :create, params: grant_proxy_params.merge(grantee_id: user.user_key)
        end

        it 'does not add the user, and returns a 200, with empty response body' do
          expect { redundant_request_to_grant_proxy }.to change { ProxyDepositRights.count }.by(0)
          expect(response).to be_success
          expect(response.body).to be_blank
        end

        it 'does not send a message to the user' do
          expect { redundant_request_to_grant_proxy }.not_to change { user.mailbox.inbox.count }
        end
      end
    end

    describe "destroy" do
      before do
        user.can_receive_deposits_from << grantee
      end

      it "is successful" do
        expect { delete :destroy, params: revoke_proxy_params }.to change { ProxyDepositRights.count }.by(-1)
      end
    end

    describe "index" do
      it "renders the page with user proxy info" do
        expect(controller).to receive(:add_breadcrumb).with('Home', root_path)
        expect(controller).to receive(:add_breadcrumb).with('Dashboard', dashboard_path)
        expect(controller).to receive(:add_breadcrumb).with('Manage Proxies', depositors_path)
        get :index
        expect(response).to be_successful
        expect(response).to render_template('dashboard')
      end
    end
  end

  context "as a user without access" do
    before do
      sign_in create(:user)
    end

    describe "create" do
      it "is not successful" do
        post :create, params: grant_proxy_params
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq "You are not authorized to access this page."
      end
    end

    describe "destroy" do
      it "is not successful" do
        delete :destroy, params: revoke_proxy_params
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq "You are not authorized to access this page."
      end
    end
  end
end
