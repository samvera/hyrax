describe TransfersController, type: :controller do
  describe "with a signed in user" do
    let(:another_user) { create(:user) }
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    describe "#index" do
      let!(:incoming_work) do
        GenericWork.new(title: ['incoming title']) do |w|
          w.apply_depositor_metadata(another_user.user_key)
          w.save!
          w.request_transfer_to(user)
        end
      end
      let!(:outgoing_work) do
        GenericWork.new(title: ['outgoing title']) do |w|
          w.apply_depositor_metadata(user.user_key)
          w.save!
          w.request_transfer_to(another_user)
        end
      end

      it "is successful" do
        get :index
        expect(response).to be_success
        expect(assigns[:incoming].first).to be_kind_of ProxyDepositRequest
        expect(assigns[:incoming].first.work_id).to eq(incoming_work.id)
        expect(assigns[:outgoing].first).to be_kind_of ProxyDepositRequest
        expect(assigns[:outgoing].first.work_id).to eq(outgoing_work.id)
      end

      describe "When the incoming request is for a deleted work" do
        before do
          incoming_work.destroy
        end
        it "does not show that work" do
          get :index
          expect(response).to be_success
          expect(assigns[:incoming]).to be_empty
        end
      end
    end

    describe "#new" do
      let(:work) do
        GenericWork.create!(title: ['a work']) do |w|
          w.apply_depositor_metadata(user.user_key)
        end
      end
      context 'when user is the depositor' do
        it "is successful" do
          sign_in user
          get :new, id: work.id
          expect(response).to be_success
          expect(assigns[:generic_work]).to eq(work)
          expect(assigns[:proxy_deposit_request]).to be_kind_of ProxyDepositRequest
          expect(assigns[:proxy_deposit_request].work_id).to eq(work.id)
        end
      end
    end

    describe "#create" do
      let(:work) do
        GenericWork.create!(title: ['a work']) do |w|
          w.apply_depositor_metadata(user.user_key)
        end
      end
      it "is successful" do
        allow_any_instance_of(User).to receive(:display_name).and_return("Jill Z. User")
        expect {
          post :create, id: work.id, proxy_deposit_request: { transfer_to: another_user.user_key }
        }.to change(ProxyDepositRequest, :count).by(1)
        expect(response).to redirect_to @routes.url_helpers.transfers_path
        expect(flash[:notice]).to eq('Transfer request created')
        proxy_request = another_user.proxy_deposit_requests.first
        expect(proxy_request.work_id).to eq(work.id)
        expect(proxy_request.sending_user).to eq(user)
        # AND A NOTIFICATION SHOULD HAVE BEEN CREATED
        notification = another_user.reload.mailbox.inbox[0].messages[0]
        expect(notification.subject).to eq("Ownership Change Request")
        expect(notification.body).to eq("<a href=\"/users/#{user.user_key}\">#{user.name}</a> wants to transfer a work to you. Review all <a href=\"#{@routes.url_helpers.transfers_path}\">transfer requests</a>")
      end
      it "gives an error if the user is not found" do
        expect {
          post :create, id: work.id, proxy_deposit_request: { transfer_to: 'foo' }
        }.not_to change(ProxyDepositRequest, :count)
        expect(assigns[:proxy_deposit_request].errors[:transfer_to]).to eq(['must be an existing user'])
        expect(response).to redirect_to(root_path)
      end
    end

    describe "#accept" do
      context "when I am the receiver" do
        let!(:incoming_work) do
          GenericWork.new(title: ['incoming']) do |w|
            w.apply_depositor_metadata(another_user.user_key)
            w.save!
            w.request_transfer_to(user)
          end
        end
        it "is successful when retaining access rights" do
          put :accept, id: user.proxy_deposit_requests.first
          expect(response).to redirect_to @routes.url_helpers.transfers_path
          expect(flash[:notice]).to eq("Transfer complete")
          expect(assigns[:proxy_deposit_request].status).to eq('accepted')
          expect(incoming_work.reload.edit_users).to eq([another_user.user_key, user.user_key])
        end
        it "is successful when resetting access rights" do
          put :accept, id: user.proxy_deposit_requests.first, reset: true
          expect(response).to redirect_to @routes.url_helpers.transfers_path
          expect(flash[:notice]).to eq("Transfer complete")
          expect(assigns[:proxy_deposit_request].status).to eq('accepted')
          expect(incoming_work.reload.edit_users).to eq([user.user_key])
        end
        it "handles sticky requests" do
          put :accept, id: user.proxy_deposit_requests.first, sticky: true
          expect(response).to redirect_to @routes.url_helpers.transfers_path
          expect(flash[:notice]).to eq("Transfer complete")
          expect(assigns[:proxy_deposit_request].status).to eq('accepted')
          expect(user.can_receive_deposits_from).to include(another_user)
        end
      end

      context "accepting one that isn't mine" do
        let!(:incoming_work) do
          GenericWork.new(title: ['incoming']) do |w|
            w.apply_depositor_metadata(user.user_key)
            w.save!
            w.request_transfer_to(another_user)
          end
        end
        it "does not allow me" do
          put :accept, id: another_user.proxy_deposit_requests.first
          expect(response).to redirect_to root_path
          expect(flash[:alert]).to eq("You are not authorized to access this page.")
        end
      end
    end

    describe "#reject" do
      context "when I am the receiver" do
        let!(:incoming_work) do
          GenericWork.new(title: ['incoming']) do |w|
            w.apply_depositor_metadata(another_user.user_key)
            w.save!
            w.request_transfer_to(user)
          end
        end
        it "is successful" do
          put :reject, id: user.proxy_deposit_requests.first
          expect(response).to redirect_to @routes.url_helpers.transfers_path
          expect(flash[:notice]).to eq("Transfer rejected")
          expect(assigns[:proxy_deposit_request].status).to eq('rejected')
        end
      end

      context "accepting one that isn't mine" do
        let!(:incoming_work) do
          GenericWork.new(title: ['incoming']) do |w|
            w.apply_depositor_metadata(user.user_key)
            w.save!
            w.request_transfer_to(another_user)
          end
        end
        it "does not allow me" do
          put :reject, id: another_user.proxy_deposit_requests.first
          expect(response).to redirect_to root_path
          expect(flash[:alert]).to eq("You are not authorized to access this page.")
        end
      end
    end

    describe "#destroy" do
      context "when I am the sender" do
        let!(:incoming_work) do
          GenericWork.new(title: ['incoming']) do |w|
            w.apply_depositor_metadata(user.user_key)
            w.save!
            w.request_transfer_to(another_user)
          end
        end
        it "is successful" do
          delete :destroy, id: another_user.proxy_deposit_requests.first
          expect(response).to redirect_to @routes.url_helpers.transfers_path
          expect(flash[:notice]).to eq("Transfer canceled")
        end
      end

      context "accepting one that isn't mine" do
        let!(:incoming_work) do
          GenericWork.new(title: ['incoming']) do |w|
            w.apply_depositor_metadata(another_user.user_key)
            w.save!
            w.request_transfer_to(user)
          end
        end
        it "does not allow me" do
          delete :destroy, id: user.proxy_deposit_requests.first
          expect(response).to redirect_to root_path
          expect(flash[:alert]).to eq("You are not authorized to access this page.")
        end
      end
    end
  end
end
