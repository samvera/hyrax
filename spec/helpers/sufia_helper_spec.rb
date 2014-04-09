require 'spec_helper'

describe SufiaHelper do

  describe "#link_to_facet_list" do
    before { helper.stub(blacklight_config: CatalogController.blacklight_config) }

    context "with values" do
      subject { helper.link_to_facet_list(['car', 'truck'], 'vehicle_type') }

      it "should join the values" do
        car_link = root_path(f: {'vehicle_type_sim' => ['car']})
        truck_link = root_path(f: {'vehicle_type_sim' => ['truck']})
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
end
