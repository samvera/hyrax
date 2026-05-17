# frozen_string_literal: true

RSpec.describe Hyrax::RedirectsController, type: :controller do
  routes { Rails.application.routes }

  describe '#show' do
    let(:work_id) { 'abc-123-xyz' }
    let(:work_uuid_path) { "/concern/generic_works/#{work_id}" }
    let(:display_path) { '/robs-cat-study' }

    before do
      allow(Hyrax.config).to receive(:redirects_enabled?).and_return(true)
      allow(Flipflop).to receive(:redirects?).and_return(true)
      Hyrax::RedirectPath.delete_all
    end

    context 'with a path that resolves to a work (no display alias)' do
      before do
        Hyrax::RedirectPath.create!(source_path: '/handle/12345/678',
                                    target_path: work_uuid_path,
                                    resource_id: work_id)
      end

      it '301-redirects to the row target_path (the UUID path)' do
        get :show, params: { alias_path: 'handle/12345/678' }
        expect(response).to have_http_status(:moved_permanently)
        expect(response.headers['Location']).to include(work_uuid_path)
      end
    end

    context 'with a path that resolves to a work that has a display alias' do
      before do
        Hyrax::RedirectPath.create!(source_path: '/handle/12345/678',
                                    target_path: display_path,
                                    resource_id: work_id)
        Hyrax::RedirectPath.create!(source_path: display_path,
                                    target_path: display_path,
                                    display: true,
                                    resource_id: work_id)
      end

      it '301-redirects to the display alias path' do
        get :show, params: { alias_path: 'handle/12345/678' }
        expect(response).to have_http_status(:moved_permanently)
        expect(response.headers['Location']).to include(display_path)
      end

      it '301-redirects to the display alias even when hitting the display alias path itself' do
        get :show, params: { alias_path: 'robs-cat-study' }
        expect(response).to have_http_status(:moved_permanently)
        expect(response.headers['Location']).to include(display_path)
      end
    end

    context 'with a path that has no matching redirect row' do
      it 'raises ActionController::RoutingError so Rails serves a 404' do
        expect { get :show, params: { alias_path: 'no-such-path' } }
          .to raise_error(ActionController::RoutingError)
      end
    end

    context 'when the incoming path needs normalization' do
      before do
        Hyrax::RedirectPath.create!(source_path: '/handle/12345/678',
                                    target_path: work_uuid_path,
                                    resource_id: work_id)
      end

      it 'normalizes the input before looking up' do
        get :show, params: { alias_path: 'handle/12345/678/' }
        expect(response).to have_http_status(:moved_permanently)
        expect(response.headers['Location']).to include(work_uuid_path)
      end
    end
  end
end
