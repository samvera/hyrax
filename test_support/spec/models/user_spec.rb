require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "active_fedora"

describe User do

  describe "superuser" do
    before(:all) do
      @orig_deprecation_behavior = Hydra::SuperuserAttributes.deprecation_behavior
      Hydra::SuperuserAttributes.deprecation_behavior = :silence

      @orig_su_deprecation_behavior = Superuser.deprecation_behavior
      Superuser.deprecation_behavior = :silence
    end
    after(:all) do
      Hydra::SuperuserAttributes.deprecation_behavior = @orig_deprecation_behavior
      Superuser.deprecation_behavior = @orig_su_deprecation_behavior
    end

    before(:each) do
      @user = User.create(:email=> "testuser@example.com", :password=> "password", :password_confirmation => "password")
    end
    it "should know if a user can be a superuser" do
      superuser = Superuser.new()
      superuser.id = 20
      superuser.user_id = @user.id
      superuser.save!
      @user.extend(Hydra::SuperuserAttributes)
      @user.can_be_superuser?.should be_true
    end

    it "should know if a user shouldn't be a superuser" do
      @user.extend(Hydra::SuperuserAttributes)
      @user.can_be_superuser?.should be_false
    end

    it "should know if the user is being a superuser" do
      superuser = Superuser.new()
      superuser.id = 50
      superuser.user_id = @user.id
      superuser.save!
      @user.extend(Hydra::SuperuserAttributes)
      session = { :superuser_mode => true }
      @user.is_being_superuser?(session).should be_true
    end

    it "should not let a non-superuser be a superuser" do
      @user.extend(Hydra::SuperuserAttributes)
      session = {}
      @user.is_being_superuser?(session).should be_false
    end

    it "should know if the user is not being a superuser even if the user can be a superuser" do
      superuser = Superuser.new()
      superuser.id = 60
      superuser.user_id = @user.id
      superuser.save!
      @user.extend(Hydra::SuperuserAttributes)
      @user.can_be_superuser?.should be_true
      session = {}
      @user.is_being_superuser?(session).should be_false
    end
  end
end

module UserTestAttributes
  ['first_name','last_name','full_name','affiliation','photo'].each do |attr|
    class_eval <<-EOM
      def #{attr}
        "test_#{attr}"
      end
    EOM
  end
end
