# frozen_string_literal: true
RSpec.describe 'Routes for single use links', type: :routing do
  routes { Hyrax::Engine.routes }

  describe 'Single Use Link Viewer' do
    it 'routes to #show' do
      expect(show_single_use_link_path('abc123')).to eq '/single_use_link/show/abc123'
      expect(get("/single_use_link/show/abc123")).to route_to("hyrax/single_use_links_viewer#show", id: 'abc123')
    end

    it 'routes to #download' do
      expect(download_single_use_link_path('abc123')).to eq '/single_use_link/download/abc123'
      expect(get("/single_use_link/download/abc123")).to route_to("hyrax/single_use_links_viewer#download", id: 'abc123')
    end
  end

  describe 'Single Use Link Generator' do
    it 'routes to #create_show' do
      expect(generate_show_single_use_link_path('abc123')).to eq '/single_use_link/generate_show/abc123'
      expect(post("/single_use_link/generate_show/abc123")).to route_to("hyrax/single_use_links#create_show", id: 'abc123')
    end

    it 'routes to #create_download' do
      expect(generate_download_single_use_link_path('abc123')).to eq '/single_use_link/generate_download/abc123'
      expect(post("/single_use_link/generate_download/abc123")).to route_to("hyrax/single_use_links#create_download", id: 'abc123')
    end
  end
end
