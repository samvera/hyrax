require 'spec_helper'

module CurationConcerns
  describe 'routing' do
    before(:all) do
      @generic_work = FactoryGirl.create(:generic_work) # Preload once to save time
    end

    describe 'Classify concerns' do
      routes { CurationConcerns::Engine.routes }
      it 'routes to #new' do
        expect(new_classify_concern_path).to eq '/classify_concerns/new'
        expect(get('/classify_concerns/new')).to route_to('curation_concerns/classify_concerns#new')
      end
    end

    describe 'generic work' do
      routes { Rails.application.routes }
      let(:generic_work) { @generic_work }
      it 'routes to #new' do
        expect(new_curation_concerns_generic_work_path).to eq '/concern/generic_works/new'
        expect(get('/concern/generic_works/new')).to route_to('curation_concerns/generic_works#new')
      end
      it 'routes to #show' do
        expect(curation_concerns_generic_work_path(generic_work)).to eq "/concern/generic_works/#{generic_work.id}"
        expect(get("/concern/generic_works/#{generic_work.id}")).to route_to(controller: 'curation_concerns/generic_works', action: 'show', id: generic_work.id)
        expect(url_for([:curation_concerns, generic_work, only_path: true])).to eq "/concern/generic_works/#{generic_work.id}"
      end
      it 'routes to #edit' do
        expect(edit_curation_concerns_generic_work_path(generic_work)).to eq "/concern/generic_works/#{generic_work.id}/edit"
        expect(get("/concern/generic_works/#{generic_work.id}/edit")).to route_to(controller: 'curation_concerns/generic_works', action: 'edit', id: generic_work.id)
        expect(url_for([:edit, :curation_concerns, generic_work, only_path: true])).to eq "/concern/generic_works/#{generic_work.id}/edit"
      end
    end
  end
end
