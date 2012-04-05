require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Ability do

  describe "initialize" do
    it "should automatically add logged-in users to 'registered' group" do
      mock_user = mock("User")
      mock_user.stubs(:email).returns "logged_in_person@example.com"
      mock_user.stubs(:is_being_superuser?).returns false
      ability = Ability.new(nil)
      ability.user_groups.should_not include 'registered'
      ability = Ability.new(mock_user)
      ability.user_groups.should include 'registered'
    end
  end

  it "should call custom_permissions" do
      Ability.any_instance.expects(:custom_permissions)
      ability = Ability.new(nil)
      ability.can?(:delete, 7)
  end
end
