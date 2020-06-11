# frozen_string_literal: true
RSpec.describe 'Operations routes', type: :routing do
  routes { Hyrax::Engine.routes }

  it 'routes the list view' do
    expect(get: '/users/77/operations').to route_to(controller: 'hyrax/operations',
                                                    action: 'index',
                                                    user_id: "77")
  end
end
