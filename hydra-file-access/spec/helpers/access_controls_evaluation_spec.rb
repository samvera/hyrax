require 'spec_helper'

describe Hydra::AccessControlsEvaluation do
  
  describe "editor?" do
    it "should return true if current_user.is_being_superuser? is true" do
      mock_user = FactoryGirl.build(:user, :email => "BigWig@example.com")
      mock_user.stub(:is_being_superuser?).and_return true
      controller.stub(:current_user).and_return mock_user
      helper.editor?.should be_true
    end
    it "should return false if the session[:user] is not logged in" do
      controller.stub(:current_user).and_return(nil)
      helper.editor?.should be_false
    end    
    it "should return false if the session[:user] does not have an editor role" do
      mock_user = mock("User")
      mock_user.stub(:email).and_return "nobody_special@example.com"
      mock_user.stub(:is_being_superuser?).and_return(false)
      mock_user.stub(:new_record?).and_return(false)
      controller.stub(:current_user).and_return(mock_user)
      helper.editor?.should be_false
    end
  end  
  
end
