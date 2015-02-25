require 'spec_helper'

describe API::ZoteroController, type: :controller do
  let(:user) { FactoryGirl.find_or_create(:jill) }

  context 'with an HTTP GET to /api/zotero' do
    context 'with an unauthenticated client' do
      before { get :initiate }

      subject { response }

      it { is_expected.to have_http_status(302) }
      it 'describes the redirect' do
        expect(flash[:alert]).to eq 'You need to sign in or sign up before continuing.'
      end
    end

    context 'with an unregistered user' do
      before do
        allow_any_instance_of(Ability).to receive(:user_groups) { ['public'] }
        sign_in user
        get :initiate
      end

      subject { response }

      it { is_expected.to have_http_status(302) }
      it { is_expected.to redirect_to(root_path) }
      it 'populates the flash with an alert' do
        expect(flash[:alert]).to eq 'You are not authorized to perform this operation'
      end
    end

    context 'with an invalid key/secret combo' do
      before do
        allow(Sufia::Zotero).to receive(:config) { broken_config }
        sign_in user
        get :initiate
      end

      let(:broken_config) { Hash.new(client_key: 'foo', client_secret: 'bar') }

      subject { response }

      it { is_expected.to have_http_status(302) }
      it { is_expected.to redirect_to(root_path) }
      it 'populates the flash with an alert' do
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

      let(:token) { object_double(OAuth::RequestToken.new(client), authorize_url: 'https://www.zotero.org/oauth/authorize?identity=1&oauth_callback=http%3A%2F%2Ftest.host%2Fapi%2Fzotero%2Fcallback&oauth_token=bc2502f2750983c57224') }
      let(:client) do
        OAuth::Consumer.new(Sufia::Zotero.config['client_key'], Sufia::Zotero.config['client_secret'], {
          site: 'https://www.zotero.org',
          scheme: :query_string,
          http_method: :get,
          request_token_path: '/oauth/request',
          access_token_path: '/oauth/access',
          authorize_path: '/oauth/authorize'})
    end

      subject { response }

      it { is_expected.to have_http_status(302) }
      it 'has no flash alerts' do
        expect(flash[:alert]).to be_nil
      end
      it 'has the expected callback URL' do
        expect(subject.headers['Location']).to include('oauth_callback=http%3A%2F%2Ftest.host%2Fapi%2Fzotero%2Fcallback')
      end
    end
  end

  context 'with an HTTP POST/GET to /api/zotero/callback' do
    context 'with an unauthenticated user' do
      before { get :callback }

      subject { response }

      it { is_expected.to have_http_status(302) }
      it 'describes the redirect' do
        expect(flash[:alert]).to eq 'You need to sign in or sign up before continuing.'
      end
    end

    context 'with an unregistered user' do
      before do
        allow_any_instance_of(Ability).to receive(:user_groups) { ['public'] }
        sign_in user
        get :callback
      end

      subject { response }

      it { is_expected.to have_http_status(302) }
      it { is_expected.to redirect_to(root_path) }
      it 'populates the flash with an alert' do
        expect(flash[:alert]).to eq 'You are not authorized to perform this operation'
      end
    end

    context 'with a request lacking an oauth_token' do
      before do
        sign_in user
        get :callback
      end

      subject { response }

      it { is_expected.to have_http_status(302) }
      it { is_expected.to redirect_to(routes.url_helpers.edit_profile_path(user)) }
      it 'populates the flash with an alert' do
        expect(flash[:alert]).to eq 'Malformed request from Zotero'
      end
    end

    context 'with a non-matching token' do
      before do
        sign_in user
        get :callback, oauth_token: 'woohoo', oauth_verifier: '12345'
      end

      subject { response }

      it { is_expected.to have_http_status(302) }
      it { is_expected.to redirect_to(routes.url_helpers.edit_profile_path(user)) }
      it 'populates the flash with an alert' do
        expect(flash[:alert]).to eq 'You have not yet connected to Zotero'
      end
    end

    context 'with a signed-in, valid user' do
      before do
        allow_any_instance_of(User).to receive(:zotero_token) { user_token }
        allow(Sufia.queue).to receive(:push)
        sign_in user
        get :callback, oauth_token: token_string, oauth_verifier: pin
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

      subject { response }

      it { is_expected.to have_http_status(302) }
      it 'pushes an arkivo subscription job' do
        expect(Sufia.queue).to have_received(:push).once
      end
      it { is_expected.to redirect_to(routes.url_helpers.profile_path(user)) }
      it 'populates the flash with a notice' do
        expect(flash[:alert]).to be_nil
        expect(flash[:notice]).to eq 'Successfully connected to Zotero!'
      end
      it 'stores the userID in the user instance' do
        expect(user.reload.zotero_userid).to eq zuserid
      end
    end
  end
end
