require 'spec_helper'

describe AuthoritiesController do
  describe "#query" do
    it "should return an array of hashes" do
      xhr :get, :query, :model=>"generic_files", :term=>"subject", :q=>"Eng"
      response.should be_success
      JSON.parse(response.body).count.should == 38
      JSON.parse(response.body)[0]["label"].should == "Extension (Philosophy)"
      JSON.parse(response.body)[0]["uri"].should == "http://lcsubjects.org/subjects/sh85046550#concept"
    end
  end
end
