# frozen_string_literal: true
RSpec.describe Hyrax::TransfersController, type: :controller do
  describe "without a signed in user" do
    describe "#index" do
      it "redirects to sign in" do
        get :index
        expect(flash[:alert]).to eq "You need to sign in or sign up before continuing."
        expect(response).to redirect_to main_app.new_user_session_path
      end
    end
  end

  describe "with a signed in user" do
    let(:another_user) { create(:user) }
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    describe "#index" do
      it "is successful" do
        expect(controller).to receive(:add_breadcrumb).exactly(3).times
        get :index
        expect(response).to be_successful
        expect(assigns[:presenter]).to be_instance_of Hyrax::TransfersPresenter
      end
    end

    describe "#new" do
      let(:work) { create(:work, user: user) }

      context 'when user is the depositor' do
        it "is successful" do
          expect(controller).to receive(:add_breadcrumb).exactly(3).times
          sign_in user
          get :new, params: { id: work.id }
          expect(response).to be_successful
          expect(assigns[:proxy_deposit_request]).to be_kind_of ProxyDepositRequest
          expect(assigns[:proxy_deposit_request].work_id).to eq(work.id)
        end
      end

      context 'with work resource' do
        let(:work) { FactoryBot.valkyrie_create(:hyrax_work, depositor: user.user_key, edit_users: [user]) }

        it "is successful" do
          expect(controller).to receive(:add_breadcrumb).exactly(3).times
          sign_in user
          get :new, params: { id: work.id }
          expect(response).to be_successful
          expect(assigns[:proxy_deposit_request]).to be_kind_of ProxyDepositRequest
          expect(assigns[:proxy_deposit_request].work_id).to eq(work.id)
        end
      end
    end

    describe "#create" do
      let(:work) { create(:work, user: user) }

      it "is successful" do
        expect do
          post :create, params: {
            id: work.id,
            proxy_deposit_request: {
              transfer_to: another_user.user_key,
              sender_comment: 'Hi mom!'
            }
          }
        end.to change(ProxyDepositRequest, :count).by(1)
        expect(response).to redirect_to routes.url_helpers.transfers_path(locale: 'en')
        expect(flash[:notice]).to eq('Transfer request created')
        proxy_request = another_user.proxy_deposit_requests.first
        expect(proxy_request.work_id).to eq(work.id)
        expect(proxy_request.sending_user).to eq(user)
        expect(proxy_request.sender_comment).to eq 'Hi mom!'
        # AND A NOTIFICATION SHOULD HAVE BEEN CREATED
        notification = another_user.reload.mailbox.inbox[0].messages[0]
        expect(notification.subject).to eq("Ownership Change Request")
        expect(notification.body).to eq("<a href=\"#{routes.url_helpers.user_path(user)}\">#{user.name}</a> " \
                                        "wants to transfer a work to you. Review all " \
                                        "<a href=\"#{routes.url_helpers.transfers_path}\">transfer requests</a>")
      end
      it "gives an error if the user is not found" do
        expect do
          post :create, params: { id: work.id, proxy_deposit_request: { transfer_to: 'foo' } }
        end.not_to change(ProxyDepositRequest, :count)
        expect(assigns[:proxy_deposit_request].errors[:transfer_to]).to eq(['Must be an existing user'])
        expect(response).to be_successful
      end

      context 'with work resource' do
        let(:work) { FactoryBot.valkyrie_create(:hyrax_work, depositor: user.user_key, edit_users: [user]) }

        it "is successful" do
          expect do
            post :create, params: {
              id: work.id,
              proxy_deposit_request: {
                transfer_to: another_user.user_key,
                sender_comment: 'Hi mom!'
              }
            }
          end.to change(ProxyDepositRequest, :count).by(1)
          expect(response).to redirect_to routes.url_helpers.transfers_path(locale: 'en')
          expect(flash[:notice]).to eq('Transfer request created')
          proxy_request = another_user.proxy_deposit_requests.first
          expect(proxy_request.work_id).to eq(work.id)
          expect(proxy_request.sending_user).to eq(user)
          expect(proxy_request.sender_comment).to eq 'Hi mom!'
          # AND A NOTIFICATION SHOULD HAVE BEEN CREATED
          notification = another_user.reload.mailbox.inbox[0].messages[0]
          expect(notification.subject).to eq("Ownership Change Request")
          expect(notification.body).to eq("<a href=\"#{routes.url_helpers.user_path(user)}\">#{user.name}</a> " \
                  "wants to transfer a work to you. Review all " \
                  "<a href=\"#{routes.url_helpers.transfers_path}\">transfer requests</a>")
        end
        it "gives an error if the user is not found" do
          expect do
            post :create, params: { id: work.id, proxy_deposit_request: { transfer_to: 'foo' } }
          end.not_to change(ProxyDepositRequest, :count)
          expect(assigns[:proxy_deposit_request].errors[:transfer_to]).to eq(['Must be an existing user'])
          expect(response).to be_successful
        end
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
          put :accept, params: { id: user.proxy_deposit_requests.first }
          expect(response).to redirect_to routes.url_helpers.transfers_path(locale: 'en')
          expect(flash[:notice]).to eq("Transfer complete")
          expect(assigns[:proxy_deposit_request].status).to eq('accepted')
          expect(incoming_work.reload.edit_users).to match_array [another_user.user_key, user.user_key]
        end
        it "is successful when resetting access rights" do
          put :accept, params: { id: user.proxy_deposit_requests.first, reset: true }
          expect(response).to redirect_to routes.url_helpers.transfers_path(locale: 'en')
          expect(flash[:notice]).to eq("Transfer complete")
          expect(assigns[:proxy_deposit_request].status).to eq('accepted')
          expect(incoming_work.reload.edit_users).to eq([user.user_key])
        end
        it "handles sticky requests" do
          put :accept, params: { id: user.proxy_deposit_requests.first, sticky: true }
          expect(response).to redirect_to routes.url_helpers.transfers_path(locale: 'en')
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
          put :accept, params: { id: another_user.proxy_deposit_requests.first }
          expect(response).to redirect_to root_path
          expect(flash[:alert]).to eq("You are not authorized to access this page.")
        end
      end

      context 'with work resource' do
        around do |example|
          @query_class = ProxyDepositRequest.work_query_service_class
          ProxyDepositRequest.work_query_service_class = Hyrax::WorkResourceQueryService
          example.run
          ProxyDepositRequest.work_query_service_class = @query_class
        end

        context "when I am the receiver" do
          let(:work) { FactoryBot.valkyrie_create(:monograph, title: ['incoming'], depositor: another_user.user_key, edit_users: [another_user]) }
          let!(:proxy_request) { ProxyDepositRequest.create!(work_id: work.id, receiving_user: user, sending_user: another_user) }

          it "is successful when retaining access rights" do
            put :accept, params: { id: user.proxy_deposit_requests.first }
            expect(response).to redirect_to routes.url_helpers.transfers_path(locale: 'en')
            expect(flash[:notice]).to eq("Transfer complete")
            expect(assigns[:proxy_deposit_request].status).to eq('accepted')
            expect(Hyrax.query_service.find_by(id: work.id).edit_users).to match_array [another_user.user_key, user.user_key]
          end
          it "is successful when resetting access rights" do
            put :accept, params: { id: user.proxy_deposit_requests.first, reset: true }
            expect(response).to redirect_to routes.url_helpers.transfers_path(locale: 'en')
            expect(flash[:notice]).to eq("Transfer complete")
            expect(assigns[:proxy_deposit_request].status).to eq('accepted')
            expect(Hyrax.query_service.find_by(id: work.id).edit_users).to match_array [user.user_key]
          end
          it "handles sticky requests" do
            put :accept, params: { id: user.proxy_deposit_requests.first, sticky: true }
            expect(response).to redirect_to routes.url_helpers.transfers_path(locale: 'en')
            expect(flash[:notice]).to eq("Transfer complete")
            expect(assigns[:proxy_deposit_request].status).to eq('accepted')
            expect(user.can_receive_deposits_from).to include(another_user)
          end
        end

        context "accepting one that isn't mine" do
          let(:work) { FactoryBot.valkyrie_create(:monograph, title: ['incoming'], depositor: user.user_key, edit_users: [user]) }
          let!(:proxy_request) { ProxyDepositRequest.create!(work_id: work.id, receiving_user: another_user, sending_user: user) }

          it "does not allow me" do
            put :accept, params: { id: another_user.proxy_deposit_requests.first }
            expect(response).to redirect_to root_path
            expect(flash[:alert]).to eq("You are not authorized to access this page.")
          end
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
          put :reject, params: { id: user.proxy_deposit_requests.first }
          expect(response).to redirect_to routes.url_helpers.transfers_path(locale: 'en')
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
          put :reject, params: { id: another_user.proxy_deposit_requests.first }
          expect(response).to redirect_to root_path
          expect(flash[:alert]).to eq("You are not authorized to access this page.")
        end
      end

      context 'with work resource' do
        context "when I am the receiver" do
          let(:work) { FactoryBot.valkyrie_create(:monograph, title: ['incoming'], depositor: another_user.user_key, edit_users: [another_user]) }
          let!(:proxy_request) { ProxyDepositRequest.create!(work_id: work.id, receiving_user: user, sending_user: another_user) }

          it "is successful" do
            put :reject, params: { id: user.proxy_deposit_requests.first }
            expect(response).to redirect_to routes.url_helpers.transfers_path(locale: 'en')
            expect(flash[:notice]).to eq("Transfer rejected")
            expect(assigns[:proxy_deposit_request].status).to eq('rejected')
          end
        end

        context "accepting one that isn't mine" do
          let(:work) { FactoryBot.valkyrie_create(:monograph, title: ['incoming'], depositor: user.user_key, edit_users: [user]) }
          let!(:proxy_request) { ProxyDepositRequest.create!(work_id: work.id, receiving_user: another_user, sending_user: user) }

          it "does not allow me" do
            put :reject, params: { id: another_user.proxy_deposit_requests.first }
            expect(response).to redirect_to root_path
            expect(flash[:alert]).to eq("You are not authorized to access this page.")
          end
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
          delete :destroy, params: { id: another_user.proxy_deposit_requests.first }
          expect(response).to redirect_to routes.url_helpers.transfers_path(locale: 'en')
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
          delete :destroy, params: { id: user.proxy_deposit_requests.first }
          expect(response).to redirect_to root_path
          expect(flash[:alert]).to eq("You are not authorized to access this page.")
        end
      end

      context 'with work resource' do
        context "when I am the sender" do
          let(:work) { FactoryBot.valkyrie_create(:monograph, title: ['incoming'], depositor: user.user_key, edit_users: [user]) }
          let!(:proxy_request) { ProxyDepositRequest.create!(work_id: work.id, receiving_user: another_user, sending_user: user) }

          it "is successful" do
            delete :destroy, params: { id: another_user.proxy_deposit_requests.first }
            expect(response).to redirect_to routes.url_helpers.transfers_path(locale: 'en')
            expect(flash[:notice]).to eq("Transfer canceled")
          end
        end

        context "accepting one that isn't mine" do
          let(:work) { FactoryBot.valkyrie_create(:monograph, title: ['incoming'], depositor: another_user.user_key, edit_users: [another_user]) }
          let!(:proxy_request) { ProxyDepositRequest.create!(work_id: work.id, receiving_user: user, sending_user: another_user) }

          it "does not allow me" do
            delete :destroy, params: { id: user.proxy_deposit_requests.first }
            expect(response).to redirect_to root_path
            expect(flash[:alert]).to eq("You are not authorized to access this page.")
          end
        end
      end
    end
  end
end
