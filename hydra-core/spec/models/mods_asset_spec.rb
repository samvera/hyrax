require 'spec_helper'

describe ModsAsset do

  let(:asset) { ModsAsset.new nil }

  it "Should be a kind of ActiveFedora::Base" do
    expect(asset).to be_kind_of(ActiveFedora::Base)
  end

  it "should set up descMetadata and rightsMetadata datastreams" do
    expect(asset.datastreams).to have_key("rightsMetadata")
    expect(asset.datastreams["rightsMetadata"]).to be_instance_of(Hydra::Datastream::RightsMetadata)
  end

end
