# frozen_string_literal: true
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

  it 'routes POST /dashboard/collections/:child_id/remove_parent/:parent_id' do
    expect(post: '/dashboard/collections/child1/remove_parent/parent1').to route_to(
      controller: 'hyrax/dashboard/nest_collections',
      action: 'remove_relationship_above',
      child_id: 'child1',
      parent_id: 'parent1'
    )
  end

  it 'routes POST /dashboard/collections/:parent_id/remove_child/:child_id' do
    expect(post: '/dashboard/collections/parent1/remove_child/child1').to route_to(
      controller: 'hyrax/dashboard/nest_collections',
      action: 'remove_relationship_under',
      child_id: 'child1',
      parent_id: 'parent1'
    )
  end

  it 'routes POST /dashboard/collections/:id' do
    expect(post: '/dashboard/collections/id').to route_to(controller: 'hyrax/dashboard/collection_members', action: 'update_members', id: 'id')
  end
end
