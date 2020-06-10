# frozen_string_literal: true
RSpec.describe 'Collection Types Routes', type: :routing do
  routes { Hyrax::Engine.routes }

  it 'routes to #index' do
    expect(get: '/admin/collection_types').to route_to(controller: 'hyrax/admin/collection_types', action: 'index')
  end

  it 'routes to #create' do
    expect(post: '/admin/collection_types').to route_to(controller: 'hyrax/admin/collection_types', action: 'create')
  end

  it 'routes to #new' do
    expect(get: '/admin/collection_types/new').to route_to(controller: 'hyrax/admin/collection_types', action: 'new')
  end

  it 'routes to #edit' do
    expect(get: '/admin/collection_types/1/edit').to route_to(controller: 'hyrax/admin/collection_types', action: 'edit', id: '1')
  end

  it 'routes to #update (patch)' do
    expect(patch: '/admin/collection_types/1').to route_to(controller: 'hyrax/admin/collection_types', action: 'update', id: '1')
  end

  it 'routes to #update (put)' do
    expect(put: '/admin/collection_types/1').to route_to(controller: 'hyrax/admin/collection_types', action: 'update', id: '1')
  end

  it 'routes to #destroy' do
    expect(delete: '/admin/collection_types/1').to route_to(controller: 'hyrax/admin/collection_types', action: 'destroy', id: '1')
  end

  it 'does not route to #show' do
    expect(get: '/admin/collection_types/1').not_to route_to(controller: 'hyrax/admin/collection_types', action: 'show', id: '1')
  end
end
