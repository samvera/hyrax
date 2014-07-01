require 'spec_helper'

describe Collection do
  before do
    @user = FactoryGirl.create(:user)
    @collection = Collection.new(title: "test collection").tap do |c|
      c.apply_depositor_metadata(@user.user_key)
    end
  end

  after do
    @collection.delete
    @user.destroy
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

    context "with no items" do
      specify "is zero" do
        @collection.save
        expect(@collection.bytes).to eq 0
      end
    end

    context "with characterized GenericFiles" do
      let(:file) { mock_model GenericFile, file_size: ["50"] }
      before do
        allow(@collection).to receive(:members).and_return([file, file])
      end
      specify "is the sum of the files' sizes" do
        expect(@collection.bytes).to eq 100
      end
    end

  end
end
