require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HydraAccessControlsHelper do
  
  describe "test_permission" do
    it "should automatically add logged-in users to 'registered' group" do
      mock_user = mock("User", :login => "logged_in_person")
      helper.stubs(:read_groups).returns(["registered"])
      helper.stubs(:current_user).returns(nil)
      helper.test_permission(:read).should == false 
      helper.stubs(:current_user).returns(mock_user)
      helper.test_permission(:read).should == true 
    end
  end
  
  describe "editor?" do
    it "should return true if current_user.is_being_superuser? is true" do
      mock_user = mock("User", :login => "BigWig")
      mock_user.stubs(:is_being_superuser?).returns true
      helper.stubs(:current_user).returns mock_user
      helper.editor?.should be_true
    end
    it "should return false if the session[:user] is not logged in" do
      helper.stubs(:current_user).returns(nil)
      helper.editor?.should be_false
    end    
    it "should return false if the session[:user] does not have an editor role" do
      mock_user = mock("User", :login=>"nobody_special")
      mock_user.stubs(:is_being_superuser?).returns(false)
      helper.stubs(:current_user).returns(mock_user)
      helper.editor?.should be_false
    end
  end  
  
end
