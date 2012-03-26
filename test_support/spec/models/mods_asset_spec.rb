require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ModsAsset do
  
  before(:each) do
    @asset = ModsAsset.new nil
  end
  
  it "Should be a kind of ActiveFedora::Base" do
    @asset.should be_kind_of(ActiveFedora::Base)
  end
  
  it "should set up descMetadata and rightsMetadata datastreams" do
    @asset.datastreams.should have_key("descMetadata")
    @asset.datastreams["descMetadata"].should be_instance_of(Hydra::Datastream::ModsArticle)
    @asset.datastreams.should have_key("rightsMetadata")
    @asset.datastreams["rightsMetadata"].should be_instance_of(Hydra::RightsMetadata)
  end
  
end
