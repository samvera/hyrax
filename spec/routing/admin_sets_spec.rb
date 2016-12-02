describe 'AdminSet routes', type: :routing do
  routes { Sufia::Engine.routes }

  it 'routes the list view' do
    expect(get: '/admin_sets').to route_to(controller: 'sufia/admin_sets', action: 'index')
  end
end
