require 'spec_helper'

describe PropertiesDatastream do
  describe "import_url" do
    before do
      subject.import_url = 'http://example.com/somefile.txt'
    end

    it "serializes" do
      expect(subject.import_url).to eq ['http://example.com/somefile.txt']
      expect(subject.ng_xml.to_xml).to be_equivalent_to "<?xml version=\"1.0\"?><fields><importUrl>http://example.com/somefile.txt</importUrl></fields>"
    end
  end

  describe "proxy_depositor" do
    before do
      subject.proxy_depositor = 'kim@example.com'
    end

    it "serializes proxy_depositor" do
      expect(subject.proxy_depositor).to eq ['kim@example.com']
      expect(subject.ng_xml.to_xml).to be_equivalent_to "<?xml version=\"1.0\"?><fields><proxyDepositor>kim@example.com</proxyDepositor></fields>"
    end
  end

  describe "to_solr" do
    let(:doc) {
      PropertiesDatastream.new(nil, 'properties').tap do |ds|
        ds.import_url = 'http://example.com/somefile.txt'
        ds.proxy_depositor = 'kim@example.com'
      end
    }
    subject { doc.to_solr}
    it "solrizes import_url" do
      expect(subject['import_url_ssim']).to eq ['http://example.com/somefile.txt']
    end
    it "solrizes proxy_depositor" do
      expect(subject['proxy_depositor_ssim']).to eq ['kim@example.com']
    end
  end
end
