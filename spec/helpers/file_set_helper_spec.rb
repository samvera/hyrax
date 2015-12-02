require 'spec_helper'

describe FileSetHelper do
  describe "#render_collection_list" do
    context "using a file that is part of a collection" do
      let(:collection) do
        mock_model(Collection, title: "Foo Collection")
      end

      let(:fs) do
        mock_model(FileSet, collections: [collection, collection])
      end

      let(:link) do
        "<a href=\"/collections/#{collection.id}\">#{collection.title}</a>"
      end

      it "displays a comma-delimited list of collections" do
        expect(helper.render_collection_list(fs)).to eq("Is part of: " + [link, link].join(", "))
      end
    end

    context "using a file that is not part of a collection" do
      let(:fs) do
        mock_model(FileSet, collections: [])
      end

      it "renders nothing" do
        expect(helper.render_collection_list(fs)).to be_nil
      end
    end
  end
end
