require 'spec_helper'

describe FileContentDatastream, :type => :model do
  describe "#latest_version" do
    let(:file) do
      GenericFile.create do |f|
        f.add_file(File.open(fixture_path + '/world.png'), path: 'content', original_name: 'world.png')
        f.apply_depositor_metadata('mjg36')
      end
    end

    context "with one version" do
      subject { file.content.latest_version.label }
      it { is_expected.to eq "version1" }
    end

    context "with two versions" do
      before do
        file.add_file(File.open(fixture_path + '/world.png'), path: 'content', original_name: 'world.png')
        file.save
      end
      subject { file.content.latest_version.label }
      it { is_expected.to eq "version2" }
    end
  end

  describe "extract_metadata" do
    let(:datastream) { FileContentDatastream.new('foo/content') }
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

    it "should only return true when the datastream has actually changed" do
      @generic_file.add_file(File.open(fixture_path + '/world.png', 'rb'), path: 'content', original_name: 'world.png')
      expect(@generic_file.content).to be_changed
      @generic_file.save!
      expect(@generic_file.content).to_not be_changed

      # Add a thumbnail ds
      @generic_file.add_file(File.open(fixture_path + '/world.png'), path: 'thumbnail', original_name: 'world.png')
      expect(@generic_file.thumbnail).to be_changed
      expect(@generic_file.content).to_not be_changed

      retrieved_file = @generic_file.reload
      expect(retrieved_file.content).to_not be_changed
    end
  end
end
