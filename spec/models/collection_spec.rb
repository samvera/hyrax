require 'spec_helper'

describe Collection do
  before(:all) do
    @user = FactoryGirl.create(:user)
    @collection = Collection.new(:title => "test collection").tap do |c|
      c.apply_depositor_metadata(@user.user_key)
    end
  end

  after(:all) do
    @collection.delete
  end

  it "should have open visibility" do
    @collection.save
    expect(@collection.read_groups).to eq ['public']
  end

  it "should not allow a collection to be saved without a title" do
     @collection.title = nil
     expect{ @collection.save! }.to raise_error(ActiveFedora::RecordInvalid)
  end
end
