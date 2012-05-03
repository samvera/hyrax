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
      ENV["COSIGN_SERVICE"] = "mock_cookie_name"
      cookies.expects(:delete).with('mock_cookie_name')
      get :destroy
      response.should redirect_to "https://webaccess.psu.edu/cgi-bin/logout"
    end
  end

end
