# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
