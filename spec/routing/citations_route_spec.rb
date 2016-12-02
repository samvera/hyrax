describe "citations routes", type: :routing do
  routes { Sufia::Engine.routes }

  context "for works" do
    it 'routes to the controller' do
      expect(get: '/works/7/citation').to route_to(controller: 'sufia/citations', action: 'work', id: '7')
    end
    it 'builds a url' do
      expect(url_for(controller: 'sufia/citations', action: 'work', id: '7', only_path: true)).to eql('/works/7/citation')
    end
  end

  context "for files" do
    it 'routes to the controller' do
      expect(get: '/files/7/citation').to route_to(controller: 'sufia/citations', action: 'file', id: '7')
    end
    it 'builds a url' do
      expect(url_for(controller: 'sufia/citations', action: 'file', id: '7', only_path: true)).to eql('/files/7/citation')
    end
  end
end
