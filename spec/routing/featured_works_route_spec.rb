require 'spec_helper'

describe "file routes" do
  routes { Sufia::Engine.routes }
  it 'should create a featured_work' do
    { post: '/files/1/featured_work' }.should route_to(controller: 'featured_works', action: 'create', id: '1')
  end
  it 'should remove a featured_work' do
    { delete: '/files/1/featured_work' }.should route_to(controller: 'featured_works', action: 'destroy', id: '1')
  end

end
