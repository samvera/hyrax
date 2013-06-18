require 'spec_helper'

describe PropertiesDatastream do

  it "should have import_url" do
    subject.import_url = 'http://example.com/somefile.txt'
    subject.import_url.should == ['http://example.com/somefile.txt']
    subject.ng_xml.to_xml.should be_equivalent_to "<?xml version=\"1.0\"?><fields><importUrl>http://example.com/somefile.txt</importUrl></fields>"
  end

  describe "to_solr" do
    before do
      @doc = PropertiesDatastream.new.tap do |ds|
        ds.import_url = 'http://example.com/somefile.txt'
      end 
    end
    subject { @doc.to_solr}
    it "should have import_url" do
      subject['import_url_ssim'].should == ['http://example.com/somefile.txt']
    end
  end
end
