require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Hydra::AccessControlsEvaluation do
  
  describe "editor?" do
    it "should return true if current_user.is_being_superuser? is true" do
      mock_user = mock("User")
      mock_user.stubs(:email).returns "BigWig@example.com"
      mock_user.stubs(:is_being_superuser?).returns true
      controller.stubs(:current_user).returns mock_user
      helper.editor?.should be_true
    end
    it "should return false if the session[:user] is not logged in" do
      controller.stubs(:current_user).returns(nil)
      helper.editor?.should be_false
    end    
    it "should return false if the session[:user] does not have an editor role" do
      mock_user = mock("User")
      mock_user.stubs(:email).returns "nobody_special@example.com"
      mock_user.stubs(:is_being_superuser?).returns(false)
      controller.stubs(:current_user).returns(mock_user)
      helper.editor?.should be_false
    end
  end  
  
end
