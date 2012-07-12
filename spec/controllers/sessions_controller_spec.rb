require 'spec_helper'

describe SessionsController do
  describe "routing" do
    it "should send /logout to sessions#destroy" do
      {:get=>'/logout'}.should route_to(:controller=>'sessions', :action=>'destroy')
      destroy_user_session_path.should == '/logout'
    end
    it "should send /login to sessions#new" do
      {:get=>'/login'}.should route_to(:controller=>'sessions', :action=>'new')
      new_user_session_path.should == '/login'
    end
  end
  describe "#destroy" do
    it "should redirect to the central logout page and destroy the cookie" do
      request.env['COSIGN_SERVICE']='cosign-gamma-ci.dlt.psu.edu'
      cookies.expects(:delete).with('cosign-gamma-ci.dlt.psu.edu')
      get :destroy
      response.should redirect_to ScholarSphere::Application.config.logout_url
    end
  end
  describe "#new" do
    it "should redirect to the central login page" do
      get :new
      response.should redirect_to ScholarSphere::Application.config.login_url
    end
  end
end
