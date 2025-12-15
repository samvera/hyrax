# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sitemap generation', :clean_repo, type: :request do
  let(:work_id) { '8d06fd24-e84c-482b-9505-06a37a34dbe2' }
  let(:collection_id) { 'c0a0cbbd-c7fa-4d5d-b8f6-ad5fddf171fc' }
  let(:private_work_id) { '91d96555-d40f-40e5-9f27-1b20885b066a' }
  let(:xml) { Nokogiri::XML(response.body) }
  let(:locs) { xml.xpath('//xmlns:loc', 'xmlns' => 'http://www.sitemaps.org/schemas/sitemap/0.9').map(&:text) }
  before do
    solr = Blacklight.default_index.connection
    solr.add([
               {
                 id: work_id,
                 has_model_ssim: ['GenericWork'],
                 read_access_group_ssim: ['public'],
                 visibility_ssi: 'open'
               },
               {
                 id: collection_id,
                 has_model_ssim: [Hyrax.config.collection_model],
                 read_access_group_ssim: ['public'],
                 visibility_ssi: 'open'
               },
               {
                 id: private_work_id,
                 has_model_ssim: ['GenericWork'],
                 read_access_group_ssim: [],
                 visibility_ssi: 'restricted'
               }
             ])
    solr.commit
  end

  describe 'GET /sitemap' do
    it 'includes links to sub-sitemaps' do
      get '/sitemap'

      expect(response).to have_http_status(:success)
      expect(response.content_type).to match(%r{application/xml})
      expect(locs.size).to eq(16)
      expect(locs).to include(match(%r{/sitemap/#{collection_id[0]}}))
      expect(locs).to include(match(%r{/sitemap/#{work_id[0]}}))
    end
  end

  describe 'GET /sitemap/:id' do
    context 'with a work' do
      it 'generates proper Hyrax URLs for works and collections' do
        get "/sitemap/#{work_id[0]}.xml"

        expect(response).to have_http_status(:success)
        expect(response.content_type).to match(%r{application/xml})
        # Should contain work URL through main_app
        expect(locs).to include(match(%r{/concern/generic_works/#{work_id}}))
      end
      it 'only shows objects that match the index' do
        get "/sitemap/#{work_id[0]}.xml"
        expect(locs.size).to eq(1)
        expect(locs).not_to include(match(%r{/collections/#{collection_id}}))
      end
    end
    context 'with a collection' do
      it 'generates proper Hyrax URLs for works and collections' do
        get "/sitemap/#{collection_id[0]}.xml"

        expect(response).to have_http_status(:success)
        expect(response.content_type).to match(%r{application/xml})
        # Should contain collection URL through hyrax engine
        expect(locs).to include(match(%r{/collections/#{collection_id}}))
      end
    end
    context 'with a private work' do
      it 'does not include it on the show page' do
        get "/sitemap/#{private_work_id[0]}.xml"
        expect(locs).not_to include(match(%r{#{private_work_id}}))
      end
    end
  end
end
