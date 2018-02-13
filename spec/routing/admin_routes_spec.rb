RSpec.describe 'Admin Routes', type: :routing do
  routes { Hyrax::Engine.routes }

  it 'routes the appearance' do
    expect(get: '/admin/appearance').to route_to(controller: 'hyrax/admin/appearances', action: 'show')
  end

  it 'routes the statistics page' do
    expect(get: '/admin/stats').to route_to(controller: 'hyrax/admin/stats', action: 'show')
  end

  context 'reports routes' do
    it 'routes the work status report' do
      expect(get: '/admin/reports/works/status').to route_to(controller: 'hyrax/admin/reports/works', action: 'status')
    end

    it 'routes the work attributes report' do
      expect(get: '/admin/reports/works/attributes').to route_to(controller: 'hyrax/admin/reports/works', action: 'attributes')
    end

    it 'routes the work activity report' do
      expect(get: '/admin/reports/works/activity').to route_to(controller: 'hyrax/admin/reports/works', action: 'activity')
    end
  end

  it 'routes the workflows' do
    expect(get: '/admin/workflows').to route_to(controller: 'hyrax/admin/workflows', action: 'index')
  end

  it 'routes the workflow roles' do
    expect(get: '/admin/workflow_roles').to route_to(controller: 'hyrax/admin/workflow_roles', action: 'index')
  end

  describe "Features" do
    it "routes to the features controller" do
      expect(get: '/admin/features').to route_to(controller: 'hyrax/admin/features', action: 'index')
    end

    it "routes to the strategies controller" do
      expect(patch: '/admin/features/foo/strategies/bar').to route_to(controller: 'hyrax/admin/strategies', action: 'update', id: 'bar', feature_id: 'foo')
    end
  end
end
