require 'spec_helper'

describe FileContentDatastream, :type => :model do
  describe "version control" do
    before do
      f = GenericFile.new
      f.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
      f.apply_depositor_metadata('mjg36')
      f.save
      @file = f.reload
    end
    after do
      @file.delete
    end
    let(:root_version) { @file.content.versions.first }
    it "should have a list of versions including the root version" do
      expect(@file.content.versions).to be_kind_of(Array)
      expect(@file.content.versions.count).to eql(2)
    end
    it "should return a RDF::URI for the version" do
      expect(@file.content.versions.first).to be_kind_of(RDF::URI)
    end
    it "should contain the root version" do
      expect(@file.content.root_version).to eql(root_version)
    end
    context "with the latest version" do
      let(:latest_version) { @file.content.versions.last }
      it "should return the latest version" do
        expect(@file.content.latest_version.to_s).to eql(latest_version.to_s)
      end
    end
    describe "add a version" do
      before do
        @file.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
        @file.save
      end
      let(:latest_version) { @file.content.versions.last }
      let(:uuid) { @file.content.versions.last.to_s.split("/").last  }
      it "should return the root verion and two additional versions" do
        expect(@file.content.versions.count).to eql(3)
      end
      it "should return the newer version via latest_version" do
        expect(@file.content.latest_version.to_s).to eql(latest_version.to_s)
      end
      it "should return the same version using the version's UUID" do
        expect(@file.content.uuid_for(latest_version)).to eql(uuid)
      end
    end
  end

  describe "extract_metadata" do
    let(:datastream) { FileContentDatastream.new(parent_object, 'content') }
    let(:parent_object) { double('base object', uri: "#{ActiveFedora.fedora.host}#{ActiveFedora.fedora.base_path}/foo", id: 'foo', new_record?: true) }
    let(:file) { ActionDispatch::Http::UploadedFile.new(tempfile: File.new(fixture_path + '/world.png'),
                                                 filename: 'world.png') }
    before { datastream.content = file }
    let(:document) { Nokogiri::XML.parse(datastream.extract_metadata).root }
    let(:namespace) { { 'ns'=>'http://hul.harvard.edu/ois/xml/ns/fits/fits_output' } }

    it "should return an xml document", unless: $in_travis do
      expect(document.xpath('//ns:identity/@mimetype', namespace).first.value).to eq 'image/png'
    end
  end

  describe "changed?" do
    before do
      @generic_file = GenericFile.new
      @generic_file.apply_depositor_metadata('mjg36')
    end
    after do
      @generic_file.delete
    end
    it "should only return true when the datastream has actually changed" do
      @generic_file.add_file(File.open(fixture_path + '/world.png', 'rb'), 'content', 'world.png')
      expect(@generic_file.content).to be_changed
      @generic_file.save!
      expect(@generic_file.content).to_not be_changed

      # Add a thumbnail ds
      @generic_file.add_file(File.open(fixture_path + '/world.png'), 'thumbnail', 'world.png')
      expect(@generic_file.thumbnail).to be_changed
      expect(@generic_file.content).to_not be_changed

      retrieved_file = @generic_file.reload
      expect(retrieved_file.content).to_not be_changed
    end
  end
end
