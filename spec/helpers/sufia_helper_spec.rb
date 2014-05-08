require 'spec_helper'

describe SufiaHelper do

  describe "#link_to_facet_list" do
    before { helper.stub(blacklight_config: CatalogController.blacklight_config) }

    context "with values" do
      subject { helper.link_to_facet_list(['car', 'truck'], 'vehicle_type') }

      it "should join the values" do
        car_link = catalog_index_path(f: {'vehicle_type_sim' => ['car']})
        truck_link = catalog_index_path(f: {'vehicle_type_sim' => ['truck']})
        expect(subject).to eq "<a href=\"#{car_link}\">car</a>, <a href=\"#{truck_link}\">truck</a>"
        expect(subject).to be_html_safe
      end
    end

    context "without values" do
      subject { helper.link_to_facet_list([], 'vehicle_type') }

      it "should show the default text" do
        expect(subject).to eq "No value entered"
      end
    end
  end

  describe "has_collection_search_parameters?" do
    subject { helper }
    context "when cq is set" do
      before { helper.stub(params: { cq: 'foo'})  }
      it { should have_collection_search_parameters }
    end

    context "when cq is not set" do
      before { helper.stub(params: { cq: ''})  }
      it { should_not have_collection_search_parameters }
    end
  end

  describe "sufia_thumbnail_tag" do
    context "for an image object" do
      let(:document) { SolrDocument.new( mime_type_tesim: 'image/jpeg', noid_tsi: '1234') }
      it "should show the audio thumbnail" do
        rendered = helper.sufia_thumbnail_tag(document, { width: 90 })
        rendered.should match /src="\/downloads\/1234\?datastream_id=thumbnail"/
        rendered.should match /width="90"/
      end
    end
    context "for an audio object" do
      let(:document) { SolrDocument.new( mime_type_tesim: 'audio/x-wave') }
      it "should show the audio thumbnail" do
        rendered = helper.sufia_thumbnail_tag(document, {})
        rendered.should match /src="\/assets\/audio.png"/
      end
    end
    context "for an document object" do
      let(:document) { SolrDocument.new( mime_type_tesim: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document') }
      it "should show the default thumbnail" do
        rendered = helper.sufia_thumbnail_tag(document, {})
        rendered.should match /src="\/assets\/default.png"/
      end
    end
  end
end
