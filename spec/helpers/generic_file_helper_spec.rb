require 'spec_helper'

describe GenericFileHelper, :type => :helper do

  describe "#render_collection_list" do

    context "using a file that is part of a collection" do

      let(:collection) do
        mock_model(Collection, title: "Foo Collection")
      end

      let(:gf) do 
        mock_model(GenericFile, { collections: [collection, collection] })
      end

      let(:link) do
        "<a href=\"/collections/#{collection.id}\">#{collection.title}</a>"
      end

      it "should display a comma-delimited list of collections" do
        expect(helper.render_collection_list(gf)).to eq("Is part of: " + [link,link].join(", "))
      end

    end

    context "using a file that is not part of a collection" do
      
      let(:gf) do 
        mock_model(GenericFile, { collections: [] })
      end

      it "should render nothing" do
        expect(helper.render_collection_list(gf)).to be_nil
      end

    end

  end

end
