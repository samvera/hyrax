require 'spec_helper'

describe AuthoritiesController do
  describe "#query" do
    it "should return an array of hashes" do
      mock_hits = [{:label => "English", :uri => "http://example.org/eng"}, 
                   {:label => "Environment", :uri => "http://example.org/env"}, 
                   {:label => "Edge", :uri => "http://example.org/edge"}, 
                   {:label => "Edgar", :uri => "http://example.org/edga"}, 
                   {:label => "Eddie", :uri => "http://example.org/edd"},
                   {:label => "Economics", :uri => "http://example.org/eco"}]
      LocalAuthority.should_receive(:entries_by_term).and_return(mock_hits)
      xhr :get, :query, :model=>"generic_files", :term=>"subject", :q=>"E"
      response.should be_success
      JSON.parse(response.body).count.should == 6
      JSON.parse(response.body)[0]["label"].should == "English"
      JSON.parse(response.body)[0]["uri"].should == "http://example.org/eng"
    end
  end
end
