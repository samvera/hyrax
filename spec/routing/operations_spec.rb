describe 'Operations routes', type: :routing do
  routes { Sufia::Engine.routes }

  it 'routes the list view' do
    expect(get: '/users/77/operations').to route_to(controller: 'sufia/operations',
                                                    action: 'index',
                                                    user_id: "77")
  end
end
