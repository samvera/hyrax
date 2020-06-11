# frozen_string_literal: true
RSpec.describe 'ResourceSync Routes', type: :routing do
  routes { Hyrax::Engine.routes }

  it 'routes the well-known uri' do
    expect(get: '/.well-known/resourcesync').to route_to(controller: 'hyrax/resource_sync', action: 'source_description')
  end

  it 'routes the capability list' do
    expect(get: '/capabilitylist').to route_to(controller: 'hyrax/resource_sync', action: 'capability_list')
  end

  it 'routes the resource list' do
    expect(get: '/resourcelist').to route_to(controller: 'hyrax/resource_sync', action: 'resource_list')
  end

  it 'routes the change list' do
    expect(get: '/changelist').to route_to(controller: 'hyrax/resource_sync', action: 'change_list')
  end
end
