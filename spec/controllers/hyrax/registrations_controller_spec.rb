RSpec.describe Hyrax::RegistrationsController, type: :controller do
  routes { Rails.application.routes }

  before do
    allow(Flipflop).to receive(:account_signup?).and_return(account_signup_enabled)
    # Recommended by Devise: https://github.com/plataformatec/devise/wiki/How-To:-Test-controllers-with-Rails-3-and-4-%28and-RSpec%29
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  context 'with account signup enabled' do
    let(:account_signup_enabled) { true }
    describe '#new' do
      it 'renders the form' do
        get :new
        expect(response).to render_template('devise/registrations/new')
      end
    end
    describe '#create' do
      it 'processes the form' do
        post :create, params: { user: { email: "user@example.org", password: "password", password_confirmation: "password" } }
        expect(response).to redirect_to Hyrax::Engine.routes.url_helpers.dashboard_path(locale: 'en')
        expect(flash[:notice]).to eq 'Welcome! You have signed up successfully.'
      end
    end
  end
  context 'with account signup disabled' do
    let(:account_signup_enabled) { false }
    describe '#new' do
      it 'redirects with a flash message' do
        get :new
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'Account registration is disabled'
      end
    end
    describe '#create' do
      it 'redirects with a flash message' do
        post :create
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq 'Account registration is disabled'
      end
    end
  end
end
