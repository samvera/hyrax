require 'spec_helper'

describe Collection do
  let(:user) { create(:user) }
  let(:collection) do
    described_class.new(title: "test collection") do |c|
      c.apply_depositor_metadata(user)
    end
  end

  it "has open visibility" do
    collection.save
    expect(collection.read_groups).to eq ['public']
  end

  it "validates title" do
    collection.title = nil
    expect(collection).not_to be_valid
  end
end
