require 'spec_helper'

describe UserSessionsController do

  before(:each) do
    @user = mock("User")
    @user.stub(:can_be_superuser?).and_return true
    @user2 = mock("User")
    @user2.stub(:can_be_superuser?).and_return false
  end
  
  it "should allow for toggling on and off session[:superuser_mode]" do
    controller.stub(:current_user).and_return(@user)
    request.env["HTTP_REFERER"] = ""
    get :superuser
    session[:superuser_mode].should be_true
    get :superuser
    session[:superuser_mode].should be_nil
  end
  
  it "should not allow superuser_mode to be set in session if current_user is not a superuser" do
    controller.stub(:current_user).and_return(@user2)
    request.env["HTTP_REFERER"] = ""
    get :superuser
    session[:superuser_mode].should be_nil
  end
  
  it "should redirect to the referer" do
    controller.stub(:current_user).and_return(@user)
    request.env["HTTP_REFERER"] = hydra_file_assets_path
    get :superuser
    response.should redirect_to(hydra_file_assets_path)
  end
  
end
