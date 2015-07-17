require 'spec_helper'

describe Collection do
  let(:user) { create(:user) }
  let(:collection) do
    Collection.new(title: "test collection") do |c|
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

  describe "::bytes" do
    subject { collection.bytes }

    context "with no items" do
      before { collection.save }
      it { is_expected.to eq 0 }
    end

    context "with two 50 byte files" do
      let(:bitstream) { double("content", size: "50")}
      let(:file) { mock_model GenericFile, content: bitstream }

      before { allow(collection).to receive(:members).and_return([file, file]) }

      it { is_expected.to eq 100 }
    end

  end
end
