# frozen_string_literal: true

RSpec.describe Hyrax::RedirectsController, type: :controller do
  routes { Rails.application.routes }

  describe '#show' do
    let(:resource_id) { 'abc-123-xyz' }
    let(:permalink)   { "/concern/generic_works/#{resource_id}" }
    let(:display_alias) { '/handle/12345/678' }

    before do
      allow(Hyrax.config).to receive(:redirects_enabled?).and_return(true)
      allow(Flipflop).to receive(:redirects?).and_return(true)
      Hyrax::RedirectPath.delete_all
    end

    def existing_row(from_path:, to_path:, is_display_url: false)
      Hyrax::RedirectPath.create!(
        from_path: from_path,
        to_path: to_path,
        permalink_path: permalink,
        resource_id: resource_id,
        is_display_url: is_display_url
      )
    end

    context 'when no row matches the visited path' do
      it 'raises ActionController::RoutingError so Rails serves a 404' do
        expect { get :show, params: { alias_path: 'no-such-path' } }
          .to raise_error(ActionController::RoutingError)
      end
    end

    context 'when the visited path is a non-display alias' do
      before { existing_row(from_path: '/old-alias', to_path: display_alias) }

      it '301-redirects to the row\'s to_path (the display alias)' do
        get :show, params: { alias_path: 'old-alias' }
        expect(response).to have_http_status(:moved_permanently)
        expect(response.headers['Location']).to end_with(display_alias)
      end

      it 'appends ?locale=<value> to the 301 target when the visitor has a locale param' do
        get :show, params: { alias_path: 'old-alias', locale: 'fr' }
        expect(response).to have_http_status(:moved_permanently)
        expect(response.headers['Location']).to end_with("#{display_alias}?locale=fr")
      end
    end

    context 'when the visited path is the display URL itself' do
      before do
        existing_row(from_path: display_alias, to_path: display_alias, is_display_url: true)
      end

      it 'dispatches in-process to the curation-concern controller and flags the env' do
        info = { controller: 'hyrax/generic_works', action: 'show', id: resource_id }
        allow(Rails.application.routes).to receive(:recognize_path).with(permalink).and_return(info)
        target_controller = class_double('Hyrax::GenericWorksController').as_stubbed_const
        # Rails calls action_encoding_template on the target controller class when
        # assigning path_parameters; stub it so the class_double doesn't choke.
        allow(target_controller).to receive(:action_encoding_template).and_return(nil)
        expect(target_controller).to receive(:dispatch).with('show', kind_of(ActionDispatch::Request), kind_of(ActionDispatch::Response)) do |_action, request, response|
          expect(request.env['hyrax.redirects.dispatched']).to be(true)
          expect(request.path_parameters).to eq(info)
          response.body = 'inner-controller-rendered-this'
        end
        get :show, params: { alias_path: display_alias.delete_prefix('/') }
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('inner-controller-rendered-this')
      end

      it 'carries locale into the in-process dispatch when the visitor has a locale param' do
        recognized = { controller: 'hyrax/generic_works', action: 'show', id: resource_id }
        allow(Rails.application.routes).to receive(:recognize_path).with(permalink).and_return(recognized)
        target_controller = class_double('Hyrax::GenericWorksController').as_stubbed_const
        allow(target_controller).to receive(:action_encoding_template).and_return(nil)
        expect(target_controller).to receive(:dispatch).with('show', kind_of(ActionDispatch::Request), kind_of(ActionDispatch::Response)) do |_action, request, response|
          expect(request.path_parameters[:locale]).to eq('fr')
          response.body = 'rendered'
        end
        get :show, params: { alias_path: display_alias.delete_prefix('/'), locale: 'fr' }
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
