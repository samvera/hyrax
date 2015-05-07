require 'spec_helper'

describe Trophy, :type => :model do
   before(:all) do
    @trophy = Trophy.create(user_id:99,generic_work_id:"99")
  end

  it "should have a user" do
     expect(@trophy).to respond_to(:user_id)
     expect(@trophy.user_id).to eq(99)
  end

  it "should have a work" do
     expect(@trophy).to respond_to(:generic_work_id)
     expect(@trophy.generic_work_id).to eq("99")
  end

  it "should not allow six trophies" do
     (1..6).each {|n| Trophy.create(user_id:120,generic_work_id:n.to_s)}
     expect(Trophy.where(user_id:120).count).to eq(5)
     Trophy.where(user_id:120).map(&:delete)
  end
end

