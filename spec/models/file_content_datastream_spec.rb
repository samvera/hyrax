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
    it "should have a list of versions with one entry" do
      @file.content.versions.count == 1
    end
    it "should return the expected version ID" do
      skip "Skipping versions for now"
      expect(@file.content.versions.first.versionID).to eq("content.0")
    end
    it "should support latest_version" do
      skip "Skipping versions for now"
      expect(@file.content.latest_version.versionID).to eq("content.0")
    end
    it "should return the same version via get_version" do
      skip "Skipping versions for now"
      expect(@file.content.get_version("content.0").versionID).to eq(@file.content.latest_version.versionID)
    end
    it "should not barf when a garbage ID is provided to get_version"  do
      skip "Skipping versions for now"
      expect(@file.content.get_version("foobar")).to be_nil
    end
    describe "add a version" do
      before do
        @file.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
        @file.save
      end
      it "should return two versions" do
        @file.content.versions.count == 2
      end
      it "should return the newer version via latest_version" do
        skip "Skipping versions for now"
        expect(@file.content.versions.first.versionID).to eq("content.1")
      end
      it "should return the same version via get_version" do
        skip "Skipping versions for now"
        expect(@file.content.get_version("content.1").versionID).to eq(@file.content.latest_version.versionID)
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
