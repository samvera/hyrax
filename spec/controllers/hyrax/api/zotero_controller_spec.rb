# frozen_string_literal: true
RSpec.describe Hyrax::API::ZoteroController, type: :controller do
  let(:user) { create(:user) }

  subject { response }

  context 'with an HTTP GET to /api/zotero' do
    context 'with an unauthenticated client' do
      before { get :initiate }

      specify do
        expect(subject).to have_http_status(:found)
        expect(flash[:alert]).to eq 'You need to sign in or sign up before continuing.'
      end
    end

    context 'with an unregistered user' do
      before do
        allow_any_instance_of(Ability).to receive(:can?).with(:create, Hyrax.primary_work_type).and_return(false)
        sign_in user
        get :initiate
      end

      specify do
        expect(subject).to have_http_status(:found)
        expect(subject).to redirect_to(root_path)
        expect(flash[:alert]).to eq 'You are not authorized to perform this operation'
      end
    end

    context 'with an invalid key/secret combo' do
      before do
        allow(Hyrax::Zotero).to receive(:config) { broken_config }
        sign_in user

        stub_request(:get,
                     %r{https://www.zotero.org/oauth/request\?oauth_callback=http://test\.host/api/zotero/callback&oauth_consumer_key=%7B:client_key=%3E%22foo%22,%20:client_secret=%3E%22bar%22%7D})
          .to_return(status: 401, body: "oauth_problem=consumer_key_unknown")
        get :initiate
      end

      let(:broken_config) { Hash.new(client_key: 'foo', client_secret: 'bar') }

      specify do
        expect(subject).to have_http_status(:found)
        expect(subject).to redirect_to(root_path)
        expect(flash[:alert]).to eq 'Invalid Zotero client key pair'
      end
    end

    describe 'redirects to Zotero' do
      before do
        allow(controller).to receive(:client) { client }
        allow(client).to receive(:get_request_token) { token }
        allow_any_instance_of(User).to receive(:zotero_token=)
        sign_in user
        get :initiate
      end

      let(:token) do
        object_double(OAuth::RequestToken.new(client),
                      authorize_url: 'https://www.zotero.org/oauth/authorize?identity=1&oauth_callback=http%3A%2F%2Ftest.host%2Fapi%2Fzotero%2Fcallback&oauth_token=bc2502f2750983c57224')
      end
      let(:client) do
        OAuth::Consumer.new(Hyrax::Zotero.config['client_key'],
                            Hyrax::Zotero.config['client_secret'],
                            site: 'https://www.zotero.org',
                            scheme: :query_string,
                            http_method: :get,
                            request_token_path: '/oauth/request',
                            access_token_path: '/oauth/access',
                            authorize_path: '/oauth/authorize')
      end

      specify do
        expect(subject).to have_http_status(:found)
        expect(flash[:alert]).to be_nil
        expect(subject.headers['Location']).to include('oauth_callback=http%3A%2F%2Ftest.host%2Fapi%2Fzotero%2Fcallback')
      end
    end
  end

  context 'with an HTTP POST/GET to /api/zotero/callback' do
    context 'with an unauthenticated user' do
      before { get :callback }

      specify do
        expect(subject).to have_http_status(:found)
        expect(flash[:alert]).to eq 'You need to sign in or sign up before continuing.'
      end
    end

    context 'with a user who is not permitted to make works' do
      before do
        allow_any_instance_of(Ability).to receive(:can?).with(:create, Hyrax.primary_work_type).and_return(false)
        sign_in user
        get :callback
      end

      specify do
        expect(subject).to have_http_status(:found)
        expect(subject).to redirect_to(root_path)
        expect(flash[:alert]).to eq 'You are not authorized to perform this operation'
      end
    end

    context 'with a request lacking an oauth_token' do
      before do
        sign_in user
        get :callback
      end

      specify do
        expect(subject).to have_http_status(:found)
        expect(subject).to redirect_to(routes.url_helpers.edit_dashboard_profile_path(user, locale: 'en'))
        expect(flash[:alert]).to eq 'Malformed request from Zotero'
      end
    end

    context 'with a non-matching token' do
      before do
        sign_in user
        get :callback, params: { oauth_token: 'woohoo', oauth_verifier: '12345' }
      end

      specify do
        expect(subject).to have_http_status(:found)
        expect(subject).to redirect_to(routes.url_helpers.edit_dashboard_profile_path(user, locale: 'en'))
        expect(flash[:alert]).to eq 'You have not yet connected to Zotero'
      end
    end

    context 'with a signed-in, valid user' do
      before do
        allow_any_instance_of(User).to receive(:zotero_token) { user_token }
        allow(Hyrax::Arkivo::CreateSubscriptionJob).to receive(:perform_later)
        sign_in user
        get :callback, params: { oauth_token: token_string, oauth_verifier: pin }
      end

      let(:token_string) { 'woohoo' }
      let(:pin) { '12345' }
      let(:user_token) do
        double('token',
               params: { oauth_token: token_string },
               get_access_token: access_token)
      end
      let(:zuserid) { 'myzuser' }
      let(:access_token) do
        double('access', params: { userID: zuserid })
      end

      specify do
        expect(subject).to have_http_status(:found)
        expect(Hyrax::Arkivo::CreateSubscriptionJob).to have_received(:perform_later)
        expect(subject).to redirect_to(routes.url_helpers.dashboard_profile_path(user, locale: 'en'))
        expect(flash[:alert]).to be_nil
        expect(flash[:notice]).to eq 'Successfully connected to Zotero!'
        expect(user.reload.zotero_userid).to eq zuserid
      end
    end
  end
end
