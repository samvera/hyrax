require 'spec_helper'

describe Trophy do
   before(:all) do
    @trophy = Trophy.create(user_id:99,generic_file_id:"99")
  end
  after(:all) do
    @trophy.delete
  end

  it "should have a user" do
     @trophy.should respond_to(:user_id)
     @trophy.user_id.should == 99
  end
  it "should have a file" do
     @trophy.should respond_to(:generic_file_id)
     @trophy.generic_file_id.should == "99"
  end

  it "should not allow six trophies" do
     (1..6).each {|n| Trophy.create(user_id:120,generic_file_id:n.to_s)}
     Trophy.where(user_id:120).count.should == 5
     Trophy.where(user_id:120).map(&:delete)
  end
end

