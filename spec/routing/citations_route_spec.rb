# frozen_string_literal: true
RSpec.describe "citations routes", type: :routing do
  routes { Hyrax::Engine.routes }

  context "for works" do
    it 'routes to the controller' do
      expect(get: '/works/7/citation').to route_to(controller: 'hyrax/citations', action: 'work', id: '7')
    end
    it 'builds a url' do
      expect(url_for(controller: 'hyrax/citations', action: 'work', id: '7', only_path: true)).to eql('/works/7/citation')
    end
  end

  context "for files" do
    it 'routes to the controller' do
      expect(get: '/files/7/citation').to route_to(controller: 'hyrax/citations', action: 'file', id: '7')
    end
    it 'builds a url' do
      expect(url_for(controller: 'hyrax/citations', action: 'file', id: '7', only_path: true)).to eql('/files/7/citation')
    end
  end
end
