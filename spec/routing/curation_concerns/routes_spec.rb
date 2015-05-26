require "spec_helper"

module CurationConcerns
  describe "routing" do

    describe "Classify concerns" do
      routes { CurationConcerns::Engine.routes }
      it "routes to #new" do
        expect(new_classify_concern_path).to eq '/classify_concerns/new'
        expect(get("/classify_concerns/new")).to route_to("curation_concerns/classify_concerns#new")
      end
    end

    describe "generic work" do
      routes { Rails.application.routes }
      it 'routes to #new' do
        expect(new_curation_concern_generic_work_path).to eq '/concern/generic_works/new'
        expect(get("/concern/generic_works/new")).to route_to("curation_concern/generic_works#new")
      end
    end
  end
end
