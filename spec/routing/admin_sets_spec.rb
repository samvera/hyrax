describe 'AdminSet routes', type: :routing do
  routes { Hyrax::Engine.routes }

  it 'routes the list view' do
    expect(get: '/admin_sets').to route_to(controller: 'hyrax/admin_sets', action: 'index')
  end
end
