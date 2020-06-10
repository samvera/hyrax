# frozen_string_literal: true
RSpec.describe 'Collection Permission Templates Routes', type: :routing do
  routes { Hyrax::Engine.routes }

  it 'routes to #create' do
    expect(post: '/dashboard/collections/1/permission_template').to route_to(controller: 'hyrax/admin/permission_templates', action: 'create', collection_id: '1')
  end

  it 'routes to #new' do
    expect(get: '/dashboard/collections/permission_template/new').to route_to(controller: 'hyrax/admin/permission_templates', action: 'new')
  end

  it 'routes to #edit' do
    expect(get: '/dashboard/collections/1/permission_template/edit').to route_to(controller: 'hyrax/admin/permission_templates', action: 'edit', collection_id: '1')
  end

  it 'routes to #show' do
    expect(get: '/dashboard/collections/1/permission_template').to route_to(controller: 'hyrax/admin/permission_templates', action: 'show', collection_id: '1')
  end

  it 'routes to #update (patch)' do
    expect(patch: '/dashboard/collections/1/permission_template').to route_to(controller: 'hyrax/admin/permission_templates', action: 'update', collection_id: '1')
  end

  it 'routes to #update (put)' do
    expect(put: '/dashboard/collections/1/permission_template').to route_to(controller: 'hyrax/admin/permission_templates', action: 'update', collection_id: '1')
  end

  it 'routes to #destroy' do
    expect(delete: '/dashboard/collections/1/permission_template').to route_to(controller: 'hyrax/admin/permission_templates', action: 'destroy', collection_id: '1')
  end
end
