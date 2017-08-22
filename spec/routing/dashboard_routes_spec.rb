RSpec.describe 'Dashboard Routes', type: :routing do
  routes { Hyrax::Engine.routes }

  it 'routes GET /dashboard/collections/:child_id/within' do
    expect(get: '/dashboard/collections/child1/within').to route_to(controller: 'hyrax/dashboard/nest_collections', action: 'new_within', child_id: 'child1')
  end

  it 'routes POST /dashboard/collections/:child_id/within' do
    expect(post: '/dashboard/collections/child1/within').to route_to(controller: 'hyrax/dashboard/nest_collections', action: 'create_within', child_id: 'child1')
  end
end
