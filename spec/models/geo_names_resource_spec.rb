require 'spec_helper'

describe GeoNamesResource, type: :model do
  it "finds locations" do
    hits = described_class.find_location("State")
    expect(hits).not_to be_nil
  end
end
