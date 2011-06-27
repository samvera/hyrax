require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UserSessionsController do

  before(:each) do
    @user = mock("User")
    @user.stubs(:can_be_superuser?).returns true
    @user2 = mock("User")
    @user2.stubs(:can_be_superuser?).returns false
  end
  
  it "should allow for toggling on and off session[:superuser_mode]" do
    controller.stubs(:current_user).returns(@user)
    request.env["HTTP_REFERER"] = ""
    get :superuser
    session[:superuser_mode].should be_true
    get :superuser
    session[:superuser_mode].should be_nil
  end
  
  it "should not allow superuser_mode to be set in session if current_user is not a superuser" do
    controller.stubs(:current_user).returns(@user2)
    request.env["HTTP_REFERER"] = ""
    get :superuser
    session[:superuser_mode].should be_nil
  end
  
  it "should redirect to the referer" do
    controller.stubs(:current_user).returns(@user)
    request.env["HTTP_REFERER"] = file_assets_path
    get :superuser
    response.should redirect_to(file_assets_path)
  end
  
end