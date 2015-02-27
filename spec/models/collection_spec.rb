require 'spec_helper'

describe Collection, :type => :model do
  before do
    @user = FactoryGirl.create(:user)
    @collection = Collection.new(title: "test collection").tap do |c|
      c.apply_depositor_metadata(@user.user_key)
    end
  end

  it "should have open visibility" do
    @collection.save
    expect(@collection.read_groups).to eq ['public']
  end

  it "should not allow a collection to be saved without a title" do
     @collection.title = nil
     expect{ @collection.save! }.to raise_error(ActiveFedora::RecordInvalid)
  end

  describe "::bytes" do
    subject { @collection.bytes }
    context "with no items" do
      before { @collection.save }
      it { is_expected.to eq 0 }
    end

    context "with two 50 byte files" do
      let(:bitstream) { double("content", size: "50")}
      let(:file) { mock_model GenericFile, content: bitstream }
      before { allow(@collection).to receive(:members).and_return([file, file]) }
      it { is_expected.to eq 100 }
    end

  end
end
