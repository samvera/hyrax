require 'spec_helper'

describe GeoNamesResource do

  it "should find locations" do
    hits = GeoNamesResource.find_location("State")
    hits.should_not be_nil
  end
end

