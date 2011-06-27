require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
include HydraDjatokaHelper


describe HydraDjatokaHelper do
  
  describe "hydra_djatoka_url_for" do
    it "should return the url for retrieving the given document's canonical jp2 url" do
      mock_doc = mock("document")
      mock_doc.expects(:kind_of?).with(SolrDocument).returns(true)
      mock_doc.expects(:id).returns("myPid")

      hydra_djatoka_url_for(mock_doc).should == "/get/myPid.jp2?image_server=true"
    end
    it "should work with a mash as the document" do
      mock_doc = mock("document")
      mock_doc.expects(:kind_of?).with(SolrDocument).returns(false)
      mock_doc.expects(:kind_of?).with(Mash).returns(true)      
      mock_doc.expects(:[]).with(:id).returns("myPid")

      hydra_djatoka_url_for(mock_doc).should == "/get/myPid.jp2?image_server=true"
    end
    it "should accept scale arguments" do
      mock_doc = mock("document")
      mock_doc.expects(:kind_of?).with(SolrDocument).returns(true)
      mock_doc.expects(:id).returns("myPid")

      hydra_djatoka_url_for(mock_doc, :scale=>"90").should == "/get/myPid.jp2?image_server%5Bscale%5D=90"
    end
  end
  
end