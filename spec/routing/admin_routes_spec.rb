describe 'Admin Routes', type: :routing do
  routes { Sufia::Engine.routes }

  it 'routes the admin dashboard' do
    expect(get: '/admin').to route_to(controller: 'sufia/admin', action: 'show')
  end
  it 'routes the statistics page' do
    expect(get: '/admin/stats').to route_to(controller: 'sufia/admin/stats', action: 'show')
  end

  it 'routes the workflows' do
    expect(get: '/admin/workflows').to route_to(controller: 'sufia/admin', action: 'workflows')
  end

  describe "Features" do
    it "routes to the features controller" do
      expect(get: '/admin/features').to route_to(controller: 'sufia/admin/features', action: 'index')
    end

    it "routes to the strategies controller" do
      expect(patch: '/admin/features/foo/strategies/bar').to route_to(controller: 'sufia/admin/strategies', action: 'update', id: 'bar', feature_id: 'foo')
    end
  end
end
