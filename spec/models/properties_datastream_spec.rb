require 'spec_helper'

describe PropertiesDatastream do
  it "should have proxy_depositor" do
    subject.proxy_depositor = 'kim@example.com'
    subject.proxy_depositor.should == ['kim@example.com']
    subject.ng_xml.to_xml.should be_equivalent_to "<?xml version=\"1.0\"?><fields><proxyDepositor>kim@example.com</proxyDepositor></fields>"
  end

  describe "to_solr" do
    before do
      @doc = PropertiesDatastream.new.tap do |ds|
        ds.proxy_depositor = 'kim@example.com'
      end 
    end
    subject { @doc.to_solr}
    it "should have proxy_depositor" do
      subject['proxy_depositor_ssim'].should == ['kim@example.com']
    end
  end
end
