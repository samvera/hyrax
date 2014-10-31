require 'spec_helper'

describe "file routes", :type => :routing do
  routes { Sufia::Engine.routes }
  it 'should create a featured_work' do
    expect(post: '/files/1/featured_work').to route_to(controller: 'featured_works', action: 'create', id: '1')
  end
  it 'should remove a featured_work' do
    expect(delete: '/files/1/featured_work').to route_to(controller: 'featured_works', action: 'destroy', id: '1')
  end

  it 'should update a collection of featured works' do
    expect(featured_work_lists_path).to eq '/featured_works'
    expect(post: '/featured_works').to route_to(controller: 'featured_work_lists', action: 'create')
  end
end
