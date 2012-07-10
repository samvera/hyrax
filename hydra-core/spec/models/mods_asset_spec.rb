require 'spec_helper'

describe ModsAsset do
  
  before(:each) do
    @asset = ModsAsset.new nil
  end
  
  it "Should be a kind of ActiveFedora::Base" do
    @asset.should be_kind_of(ActiveFedora::Base)
  end
  
  it "should set up descMetadata and rightsMetadata datastreams" do
    # Mods article was moved to the mods gem.  Ask cbeer about this.  Jcoyne 2012-07-10
    #@asset.datastreams.should have_key("descMetadata")
    #@asset.datastreams["descMetadata"].should be_instance_of(Hydra::Datastream::ModsArticle)
    @asset.datastreams.should have_key("rightsMetadata")
    @asset.datastreams["rightsMetadata"].should be_instance_of(Hydra::Datastream::RightsMetadata)
  end
  
end
