require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ModsAsset do
  
  before(:each) do
    Fedora::Repository.stubs(:instance).returns(stub_everything())
    @asset = ModsAsset.new
    # @asset.stubs(:create_date).returns("2008-07-02T05:09:42.015Z")
    # @asset.stubs(:modified_date).returns("2008-09-29T21:21:52.892Z")
  end
  
  it "Should be a kind of ActiveFedora::Base" do
    @asset.should be_kind_of(ActiveFedora::Base)
  end
  
  it "should set up descMetadata and rightsMetadata datastreams" do
    @asset.datastreams.should have_key("descMetadata")
    @asset.datastreams["descMetadata"].should be_instance_of(Hydra::ModsArticle)
    @asset.datastreams.should have_key("rightsMetadata")
    @asset.datastreams["rightsMetadata"].should be_instance_of(Hydra::RightsMetadata)
  end
  
  it "should have has_model relationships pointing to commonMetadata and modsObject cModels" do
    pending "this is waiting for ActiveFedora::Base to support a self.relationships method"
    @asset.relationships[:self][:has_model].should include("info:fedora/hydra-cModel:commonMetadata")
    @asset.relationships[:self][:has_model].should include("info:fedora/hydra-cModel:modsObject")
  end
  
end