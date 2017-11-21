RSpec.describe 'Dashboard Routes', type: :routing do
  routes { Hyrax::Engine.routes }

  it 'routes GET /dashboard/collections/:parent_id/under' do
    expect(get: '/dashboard/collections/parent1/under').to route_to(controller: 'hyrax/dashboard/nest_collections', action: 'create_collection_under', parent_id: 'parent1')
  end

  it 'routes POST /dashboard/collections/:parent_id/under' do
    expect(post: '/dashboard/collections/parent1/under').to route_to(controller: 'hyrax/dashboard/nest_collections', action: 'create_relationship_under', parent_id: 'parent1')
  end

  it 'routes POST /dashboard/collections/:child_id/within' do
    expect(post: '/dashboard/collections/child1/within').to route_to(controller: 'hyrax/dashboard/nest_collections', action: 'create_relationship_within', child_id: 'child1')
  end
end
