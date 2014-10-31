require 'spec_helper'

describe GeoNamesResource, :type => :model do

  it "should find locations" do
    hits = GeoNamesResource.find_location("State")
    expect(hits).not_to be_nil
  end
end

