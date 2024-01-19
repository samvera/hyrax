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

    shared_examples('loading #new action is successful') do
      it "is successful" do
        expect(controller).to receive(:add_breadcrumb).exactly(3).times
        sign_in user
        get :new, params: { id: work.id }
        expect(response).to be_successful
        expect(assigns[:proxy_deposit_request]).to be_kind_of ProxyDepositRequest
        expect(assigns[:proxy_deposit_request].work_id).to eq(work.id)
      end
    end

    describe "#new" do
      context 'with Active Fedora objects', :active_fedora do
        let(:work) { create(:work, user: user) }

        context 'when user is the depositor' do
          include_examples 'loading #new action is successful'
        end
      end
      context 'with work resource' do
        let(:work) { FactoryBot.valkyrie_create(:hyrax_work, depositor: user.user_key, edit_users: [user]) }

        include_examples 'loading #new action is successful'
      end
    end

    shared_examples('common tests for #create') do
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

    describe "#create" do
      context 'with Active Fedora objects', :active_fedora do
        let(:work) { create(:work, user: user) }

        include_examples 'common tests for #create'
      end
      context 'with work resource' do
        let(:work) { FactoryBot.valkyrie_create(:hyrax_work, depositor: user.user_key, edit_users: [user]) }

        include_examples 'common tests for #create'
      end
    end

    shared_context('with AF work with secondary depositor') do
      let!(:incoming_work) do
        GenericWork.new(title: ['incoming']) do |w|
          w.apply_depositor_metadata(another_user.user_key)
          w.save!
          w.request_transfer_to(user)
        end
      end
    end

    shared_context('with AF work with primary depositor') do
      let!(:incoming_work) do
        GenericWork.new(title: ['incoming']) do |w|
          w.apply_depositor_metadata(user.user_key)
          w.save!
          w.request_transfer_to(another_user)
        end
      end
    end

    shared_context('with Valkyrie work with primary depositor') do
      let(:work) { FactoryBot.valkyrie_create(:monograph, title: ['incoming'], depositor: user.user_key, edit_users: [user]) }
      let!(:proxy_request) { ProxyDepositRequest.create!(work_id: work.id, receiving_user: another_user, sending_user: user) }
    end

    shared_context('with Valkyrie work with secondary depositor') do
      let(:work) { FactoryBot.valkyrie_create(:monograph, title: ['incoming'], depositor: another_user.user_key, edit_users: [another_user]) }
      let!(:proxy_request) { ProxyDepositRequest.create!(work_id: work.id, receiving_user: user, sending_user: another_user) }
    end

    def common_response_tests
      expect(response).to redirect_to routes.url_helpers.transfers_path(locale: 'en')
      expect(flash[:notice]).to eq("Transfer complete")
      expect(assigns[:proxy_deposit_request].status).to eq('accepted')
    end

    shared_examples('common tests for #accept') do
      it "is successful when retaining access rights" do
        put :accept, params: { id: user.proxy_deposit_requests.first }
        common_response_tests
      end

      it "is successful when resetting access rights" do
        put :accept, params: { id: user.proxy_deposit_requests.first, reset: true }
        common_response_tests
      end

      it "handles sticky requests" do
        put :accept, params: { id: user.proxy_deposit_requests.first, sticky: true }
        common_response_tests
        expect(user.can_receive_deposits_from).to include(another_user)
      end
    end

    shared_examples('does not allow other user in #accept') do
      it "does not allow me" do
        put :accept, params: { id: another_user.proxy_deposit_requests.first }
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq("You are not authorized to access this page.")
      end
    end

    describe "#accept" do
      context 'with Active Fedora objects', :active_fedora do
        context "when I am the receiver" do
          include_context 'with AF work with secondary depositor'

          include_examples 'common tests for #accept'

          it "is successful when retaining access rights (ActiveFedora specific)" do
            put :accept, params: { id: user.proxy_deposit_requests.first }
            expect(incoming_work.reload.edit_users).to match_array [another_user.user_key, user.user_key]
          end

          it "is successful when resetting access rights (ActiveFedora specific)" do
            put :accept, params: { id: user.proxy_deposit_requests.first, reset: true }
            expect(incoming_work.reload.edit_users).to eq([user.user_key])
          end

          context "already received sticky proxy" do
            before do
              user.can_receive_deposits_from << another_user
            end
            it "handles sticky requests and does not add another user" do
              put :accept, params: { id: user.proxy_deposit_requests.first, sticky: true }
              common_response_tests
              expect(user.can_receive_deposits_from.to_a.count(another_user)).to eq 1
            end
          end
        end

        context "accepting one that isn't mine" do
          include_context 'with AF work with primary depositor'

          include_examples 'does not allow other user in #accept'
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
          include_context 'with Valkyrie work with secondary depositor'

          include_examples 'common tests for #accept'

          it "is successful when retaining access rights (Valkyrie specific)" do
            put :accept, params: { id: user.proxy_deposit_requests.first }
            expect(Hyrax.query_service.find_by(id: work.id).edit_users).to match_array [another_user.user_key, user.user_key]
          end
          it "is successful when resetting access rights (Valkyrie specific)" do
            put :accept, params: { id: user.proxy_deposit_requests.first, reset: true }
            expect(Hyrax.query_service.find_by(id: work.id).edit_users).to match_array [user.user_key]
          end
        end

        context "accepting one that isn't mine" do
          include_context 'with Valkyrie work with primary depositor'

          include_examples 'does not allow other user in #accept'
        end
      end
    end

    def common_redirect_tests
      expect(response).to redirect_to root_path
      expect(flash[:alert]).to eq("You are not authorized to access this page.")
    end

    def common_rejection_tests
      expect(response).to redirect_to routes.url_helpers.transfers_path(locale: 'en')
      expect(flash[:notice]).to eq("Transfer rejected")
      expect(assigns[:proxy_deposit_request].status).to eq('rejected')
    end

    describe "#reject" do
      context 'with Active Fedora objects', :active_fedora do
        context "when I am the receiver" do
          include_context 'with AF work with secondary depositor'

          it "is successful" do
            put :reject, params: { id: user.proxy_deposit_requests.first }
            common_rejection_tests
          end
        end

        context "accepting one that isn't mine" do
          include_context 'with AF work with primary depositor'

          it "does not allow me" do
            put :reject, params: { id: another_user.proxy_deposit_requests.first }
            common_redirect_tests
          end
        end
      end

      context 'with work resource' do
        context "when I am the receiver" do
          include_context 'with Valkyrie work with secondary depositor'

          it "is successful" do
            put :reject, params: { id: user.proxy_deposit_requests.first }
            common_rejection_tests
          end
        end

        context "accepting one that isn't mine" do
          include_context 'with Valkyrie work with primary depositor'

          it "does not allow me" do
            put :reject, params: { id: another_user.proxy_deposit_requests.first }
            common_redirect_tests
          end
        end
      end
    end

    def common_cancellation_tests
      expect(response).to redirect_to routes.url_helpers.transfers_path(locale: 'en')
      expect(flash[:notice]).to eq("Transfer canceled")
    end

    describe "#destroy" do
      context 'with Active Fedora objects', :active_fedora do
        context "when I am the sender" do
          include_context 'with AF work with primary depositor'

          it "is successful" do
            delete :destroy, params: { id: another_user.proxy_deposit_requests.first }
            common_cancellation_tests
          end
        end

        context "accepting one that isn't mine" do
          include_context 'with AF work with secondary depositor'

          it "does not allow me" do
            delete :destroy, params: { id: user.proxy_deposit_requests.first }
            common_redirect_tests
          end
        end
      end
      context 'with work resource' do
        context "when I am the sender" do
          include_context 'with Valkyrie work with primary depositor'

          it "is successful" do
            delete :destroy, params: { id: another_user.proxy_deposit_requests.first }
            common_cancellation_tests
          end
        end

        context "accepting one that isn't mine" do
          include_context 'with Valkyrie work with secondary depositor'

          it "does not allow me" do
            delete :destroy, params: { id: user.proxy_deposit_requests.first }
            common_redirect_tests
          end
        end
      end
    end
  end
end
