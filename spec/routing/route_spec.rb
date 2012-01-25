require 'spec_helper'

describe "Routes" do

  it "should have routes for generic files" do
    { :post => "/generic_files/7/audit" }.should route_to( :controller => "generic_files", :action=>'audit', :id=>"7")
  end
end
