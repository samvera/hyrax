require 'spec_helper'

describe SessionsController do
  describe "routing" do
    it "should send /logout to sessions#destroy" do
      {:get=>'/logout'}.should route_to(:controller=>'sessions', :action=>'destroy')
      logout_path.should == '/logout'
    end
  end
  describe "#destroy" do
    it "should redirect to the central logout page and destroy the cookie" do
      request.env['COSIGN_SERVICE']='cosign-gamma-ci.dlt.psu.edu'
      cookies.expects(:delete).with('cosign-gamma-ci.dlt.psu.edu')
      get :destroy
      response.should redirect_to "https://webaccess.psu.edu/cgi-bin/logout"
    end
  end

end
