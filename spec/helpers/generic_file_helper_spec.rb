require 'spec_helper'

describe GenericFileHelper do

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

  describe "download links" do
    let(:file) { GenericFile.new(id: "fake-1") }
    let(:link_text) { helper.render_download_link("Download Fake") }
    let(:icon_text) { helper.render_download_icon("Download the full-sized Fake") }

    before { assign :generic_file, file }

    describe "#render_download_link" do
      it "has default text" do
        expect(helper.render_download_link).to have_selector("#file_download")
        expect(helper.render_download_link).to have_content("Download")
      end

      it "includes user-supplied link text" do
        expect(link_text).to have_selector("#file_download")
        expect(link_text).to have_content("Download Fake")
      end
    end

    describe "#render_download_icon" do
      it "has default text" do
        expect(helper.render_download_icon).to have_selector("#file_download")
        expect(helper.render_download_icon).to match("Download the document")
      end

      it "includes user-supplied icon text" do
        expect(icon_text).to have_selector("#file_download")
        expect(icon_text).to match("Download the full-sized Fake")
      end
    end
  end
end
