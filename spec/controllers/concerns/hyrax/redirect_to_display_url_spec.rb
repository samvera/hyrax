# frozen_string_literal: true

RSpec.describe Hyrax::RedirectToDisplayUrl, type: :controller do
  controller(ActionController::Base) do
    include Hyrax::RedirectToDisplayUrl
    def show
      render plain: 'ok'
    end
  end

  before do
    routes.draw { get 'concern/generic_works/:id', to: 'anonymous#show', as: :test_show }
    Hyrax::RedirectPath.delete_all
    allow(Hyrax.config).to receive(:redirects_active?).and_return(true)
  end

  describe '#redirect_to_display_url_if_needed (as a before_action on :show)' do
    let(:resource_id) { 'res-1' }
    let(:permalink)   { "/concern/generic_works/#{resource_id}" }
    let(:display_alias) { '/the-display-alias' }

    context 'when the redirects feature is inactive' do
      before { allow(Hyrax.config).to receive(:redirects_active?).and_return(false) }

      it 'does not consult the redirects table' do
        expect(Hyrax::RedirectsLookup).not_to receive(:find_row)
        get :show, params: { id: resource_id }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the request has already been dispatched by the resolver' do
      before do
        request.env['hyrax.redirects.dispatched'] = true
        Hyrax::RedirectPath.create!(
          from_path: permalink, to_path: display_alias, permalink_path: permalink,
          resource_id: resource_id, is_display_url: false
        )
      end

      it 'does not consult the redirects table and renders normally' do
        expect(Hyrax::RedirectsLookup).not_to receive(:find_row)
        get :show, params: { id: resource_id }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when no row matches the visited path' do
      it 'renders normally without redirecting' do
        get :show, params: { id: resource_id }
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('ok')
      end
    end

    context 'when the row\'s to_path equals the visited path' do
      before do
        Hyrax::RedirectPath.create!(
          from_path: permalink, to_path: permalink, permalink_path: permalink,
          resource_id: resource_id, is_display_url: true
        )
      end

      it 'does not redirect (the visitor is already where the row points)' do
        get :show, params: { id: resource_id }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the row\'s to_path differs from the visited path' do
      before do
        Hyrax::RedirectPath.create!(
          from_path: permalink, to_path: display_alias, permalink_path: permalink,
          resource_id: resource_id, is_display_url: false
        )
      end

      it '301-redirects to the row\'s to_path' do
        get :show, params: { id: resource_id }
        expect(response).to have_http_status(:moved_permanently)
        expect(response.headers['Location']).to end_with(display_alias)
      end
    end
  end
end
