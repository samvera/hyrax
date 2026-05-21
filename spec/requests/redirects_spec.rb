# frozen_string_literal: true

RSpec.describe 'URL redirects', type: :request do
  let(:resource_id) { 'abc-123-xyz' }
  let(:permalink)   { "/concern/generic_works/#{resource_id}" }

  before { Hyrax::RedirectPath.delete_all }

  context 'with both gates open (config + Flipflop)' do
    before do
      allow(Hyrax.config).to receive(:redirects_enabled?).and_return(true)
      allow(Flipflop).to receive(:redirects?).and_return(true)
    end

    context 'with a non-display alias row' do
      before do
        Hyrax::RedirectPath.create!(
          from_path: '/handle/12345/678',
          to_path: '/the-display-alias',
          permalink_path: permalink,
          resource_id: resource_id,
          is_display_url: false
        )
      end

      it '301-redirects to the row\'s to_path' do
        get '/handle/12345/678'
        expect(response.code).to eq('301')
        expect(response.headers['Location']).to end_with('/the-display-alias')
      end
    end

    context 'with no matching row' do
      it 'does not redirect' do
        begin
          get '/no-such-path'
        rescue ActionController::RoutingError
          # some test envs raise rather than rendering 404
        end
        expect(response&.redirect?).to be_falsey
      end
    end
  end

  context 'with the config on but the Flipflop off' do
    before do
      allow(Hyrax.config).to receive(:redirects_enabled?).and_return(true)
      allow(Flipflop).to receive(:redirects?).and_return(false)
    end

    it 'does not consult the redirects table for unmatched paths' do
      expect(Hyrax::RedirectsLookup).not_to receive(:find_row)
      begin
        get '/handle/12345/678'
      rescue ActionController::RoutingError
        # some test envs raise rather than rendering 404
      end
    end
  end

  context 'with the config off' do
    before do
      allow(Hyrax.config).to receive(:redirects_enabled?).and_return(false)
    end

    it 'does not consult Flipflop or the redirects table (config short-circuits)' do
      expect(Flipflop).not_to receive(:redirects?)
      expect(Hyrax::RedirectsLookup).not_to receive(:find_row)
      begin
        get '/handle/12345/678'
      rescue ActionController::RoutingError
        # some test envs raise rather than rendering 404
      end
    end
  end
end
