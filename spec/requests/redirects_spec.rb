# frozen_string_literal: true

RSpec.describe 'URL redirects', type: :request do
  let(:work_id)        { 'abc-123-xyz' }
  let(:work_uuid_path) { "/concern/generic_works/#{work_id}" }
  let(:display_path)   { '/robs-cat-study' }

  before { Hyrax::RedirectPath.delete_all }

  context 'with both gates open (config + Flipflop)' do
    before do
      allow(Hyrax.config).to receive(:redirects_enabled?).and_return(true)
      allow(Flipflop).to receive(:redirects?).and_return(true)
      Hyrax::RedirectPath.create!(source_path: '/handle/12345/678',
                                  target_path: work_uuid_path,
                                  resource_id: work_id)
    end

    it 'resolves a registered alias path to a 301 with the target_path Location' do
      get '/handle/12345/678'
      expect(response.code).to eq('301')
      expect(response.headers['Location']).to include(work_uuid_path)
    end

    context 'when no redirect matches' do
      it 'does not redirect' do
        begin
          get '/no-such-path'
        rescue ActionController::RoutingError
          # some test envs raise rather than rendering 404
        end
        expect(response&.redirect?).to be_falsey
      end
    end

    context 'when a display alias is set' do
      before do
        # Update the existing handle row to target the display alias, plus
        # add the display row itself.
        Hyrax::RedirectPath.where(resource_id: work_id).update_all(target_path: display_path) # rubocop:disable Rails/SkipsModelValidations
        Hyrax::RedirectPath.create!(source_path: display_path,
                                    target_path: display_path,
                                    display: true,
                                    resource_id: work_id)
      end

      it '301-redirects a non-display alias to the display alias path' do
        get '/handle/12345/678'
        expect(response.code).to eq('301')
        expect(response.headers['Location']).to include(display_path)
      end
    end
  end

  context 'with the config on but the Flipflop off' do
    before do
      allow(Hyrax.config).to receive(:redirects_enabled?).and_return(true)
      allow(Flipflop).to receive(:redirects?).and_return(false)
      Hyrax::RedirectPath.create!(source_path: '/handle/12345/678',
                                  target_path: work_uuid_path,
                                  resource_id: work_id)
    end

    it 'does not resolve the alias (route is gated by the Flipflop)' do
      begin
        get '/handle/12345/678'
      rescue ActionController::RoutingError
        # some test envs raise rather than rendering 404
      end
      expect(response&.redirect?).to be_falsey
    end
  end

  context 'with the config off' do
    before do
      allow(Hyrax.config).to receive(:redirects_enabled?).and_return(false)
    end

    it 'does not consult Flipflop (config short-circuits)' do
      expect(Flipflop).not_to receive(:redirects?)
      begin
        get '/handle/12345/678'
      rescue ActionController::RoutingError
        # some test envs raise rather than rendering 404
      end
    end
  end
end
