describe "file routes", type: :routing do
  routes { Sufia::Engine.routes }

  it 'creates a featured_work' do
    expect(post: '/works/7/featured_work').to route_to(controller: 'sufia/featured_works', action: 'create', id: '7')
  end
  it 'removes a featured_work' do
    expect(delete: '/works/7/featured_work').to route_to(controller: 'sufia/featured_works', action: 'destroy', id: '7')
  end

  it 'updates a collection of featured works' do
    expect(featured_work_lists_path).to eq '/featured_works'
    expect(post: '/featured_works').to route_to(controller: 'sufia/featured_work_lists', action: 'create')
  end
end
